package handlers

import (
	"strconv"

	"synergy_dms/models"

	"github.com/gofiber/fiber/v2"
)

type DocumentHandler struct{}

func NewDocumentHandler() *DocumentHandler {
	return &DocumentHandler{}
}

type CreateDocumentRequest struct {
	Title       string                  `json:"title"`
	Description string                  `json:"description"`
	FilePath    string                  `json:"file_path"`
	Priority    models.DocumentPriority `json:"priority"`
}

type UpdateStatusRequest struct {
	Status string `json:"status"`
	Reason string `json:"reason"`
}

type DelegateRequest struct {
	NewAdminID uint `json:"new_admin_id"`
}

// GetDocuments returns documents based on user role
func (h *DocumentHandler) GetDocuments(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)
	var documents []models.Document

	query := models.DB.Preload("Creator").Preload("AssignedTo")

	switch user.Role {
	case models.RoleStudent:
		// Students see only their own documents
		query = query.Where("creator_id = ?", user.ID)
	case models.RoleAdmin:
		// Admins see docs assigned to them OR unassigned pending docs
		query = query.Where("assigned_to_id = ? OR (assigned_to_id IS NULL AND status = ?)",
			user.ID, models.StatusPending)
	case models.RoleSuperAdmin:
		// Super-Admins see all documents
	}

	// Add optional status filter
	if status := c.Query("status"); status != "" {
		query = query.Where("status = ?", status)
	}

	// Add optional priority filter
	if priority := c.Query("priority"); priority != "" {
		if p, err := strconv.Atoi(priority); err == nil {
			query = query.Where("priority = ?", p)
		}
	}

	if err := query.Order("created_at DESC").Find(&documents).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to fetch documents",
		})
	}

	var responses []models.DocumentResponse
	for _, doc := range documents {
		responses = append(responses, doc.ToResponse())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    responses,
		"count":   len(responses),
	})
}

// GetDocument returns a single document by ID
func (h *DocumentHandler) GetDocument(c *fiber.Ctx) error {
	docID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid document ID",
		})
	}

	var document models.Document
	if err := models.DB.Preload("Creator").Preload("AssignedTo").First(&document, docID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "Document not found",
		})
	}

	// Check access
	user := c.Locals("user").(*models.User)
	if user.Role == models.RoleStudent && document.CreatorID != user.ID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"success": false,
			"message": "Access denied",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    document.ToResponse(),
	})
}

// CreateDocument creates a new document
func (h *DocumentHandler) CreateDocument(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	var req CreateDocumentRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	if req.Title == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Title is required",
		})
	}

	// Validate priority
	if req.Priority < 1 || req.Priority > 3 {
		req.Priority = models.PriorityLow
	}

	document := models.Document{
		Title:       req.Title,
		Description: req.Description,
		FilePath:    req.FilePath,
		Priority:    req.Priority,
		Status:      models.StatusPending,
		CreatorID:   user.ID,
	}

	if err := models.DB.Create(&document).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to create document",
		})
	}

	// Create history entry
	history := models.History{
		DocumentID: document.ID,
		ActorID:    user.ID,
		Action:     models.ActionCreated,
		Comment:    "Document created",
	}
	models.DB.Create(&history)

	// Reload with relations
	models.DB.Preload("Creator").First(&document, document.ID)

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "Document created successfully",
		"data":    document.ToResponse(),
	})
}

// UpdateDocumentStatus updates document status (Admin/Super-Admin only)
func (h *DocumentHandler) UpdateDocumentStatus(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	docID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid document ID",
		})
	}

	var req UpdateStatusRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	// Validate status
	validStatuses := map[string]models.DocumentStatus{
		"approved": models.StatusApproved,
		"rejected": models.StatusRejected,
		"pending":  models.StatusPending,
	}

	newStatus, valid := validStatuses[req.Status]
	if !valid {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid status. Must be 'approved', 'rejected', or 'pending'",
		})
	}

	// Rejection requires reason
	if newStatus == models.StatusRejected && req.Reason == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Rejection reason is required",
		})
	}

	var document models.Document
	if err := models.DB.First(&document, docID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "Document not found",
		})
	}

	// Update document
	document.Status = newStatus
	if newStatus == models.StatusRejected {
		document.RejectionReason = req.Reason
	}

	if err := models.DB.Save(&document).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to update document status",
		})
	}

	// Create history entry
	var action models.ActionType
	var comment string
	switch newStatus {
	case models.StatusApproved:
		action = models.ActionApproved
		comment = "Document approved"
	case models.StatusRejected:
		action = models.ActionRejected
		comment = "Rejected: " + req.Reason
	default:
		action = models.ActionCreated
		comment = "Status changed to " + req.Status
	}

	history := models.History{
		DocumentID: document.ID,
		ActorID:    user.ID,
		Action:     action,
		Comment:    comment,
	}
	models.DB.Create(&history)

	// Reload with relations
	models.DB.Preload("Creator").Preload("AssignedTo").First(&document, document.ID)

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Document status updated successfully",
		"data":    document.ToResponse(),
	})
}

// DelegateDocument assigns document to another admin
func (h *DocumentHandler) DelegateDocument(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	docID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid document ID",
		})
	}

	var req DelegateRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	if req.NewAdminID == 0 {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "New admin ID is required",
		})
	}

	// Verify target admin exists and is approved
	var targetAdmin models.User
	if err := models.DB.First(&targetAdmin, req.NewAdminID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "Target admin not found",
		})
	}

	if targetAdmin.Role != models.RoleAdmin && targetAdmin.Role != models.RoleSuperAdmin {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Target user is not an admin",
		})
	}

	if !targetAdmin.IsApproved {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Target admin is not approved",
		})
	}

	var document models.Document
	if err := models.DB.First(&document, docID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "Document not found",
		})
	}

	// Update assignment
	document.AssignedToID = &req.NewAdminID

	if err := models.DB.Save(&document).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to delegate document",
		})
	}

	// Create history entry
	history := models.History{
		DocumentID: document.ID,
		ActorID:    user.ID,
		Action:     models.ActionDelegated,
		Comment:    "Delegated to " + targetAdmin.FullName,
	}
	models.DB.Create(&history)

	// Reload with relations
	models.DB.Preload("Creator").Preload("AssignedTo").First(&document, document.ID)

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Document delegated successfully",
		"data":    document.ToResponse(),
	})
}

// GetDocumentHistory returns audit log for a document
func (h *DocumentHandler) GetDocumentHistory(c *fiber.Ctx) error {
	docID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid document ID",
		})
	}

	// Verify document exists
	var document models.Document
	if err := models.DB.First(&document, docID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "Document not found",
		})
	}

	// Check access
	user := c.Locals("user").(*models.User)
	if user.Role == models.RoleStudent && document.CreatorID != user.ID {
		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"success": false,
			"message": "Access denied",
		})
	}

	var history []models.History
	if err := models.DB.Preload("Actor").Where("document_id = ?", docID).
		Order("timestamp DESC").Find(&history).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to fetch history",
		})
	}

	var responses []models.HistoryResponse
	for _, h := range history {
		responses = append(responses, h.ToResponse())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    responses,
		"count":   len(responses),
	})
}
