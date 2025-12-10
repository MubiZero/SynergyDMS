package handlers

import (
	"strconv"

	"synergy_dms/models"

	"github.com/gofiber/fiber/v2"
)

type UserHandler struct{}

func NewUserHandler() *UserHandler {
	return &UserHandler{}
}

// GetPendingAdmins returns list of admins pending approval (Super-Admin only)
func (h *UserHandler) GetPendingAdmins(c *fiber.Ctx) error {
	var users []models.User
	if err := models.DB.Where("role = ? AND is_approved = ?", models.RoleAdmin, false).Find(&users).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to fetch pending admins",
		})
	}

	var responses []models.UserResponse
	for _, user := range users {
		responses = append(responses, user.ToResponse())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    responses,
		"count":   len(responses),
	})
}

// ApproveAdmin approves an admin (Super-Admin only)
func (h *UserHandler) ApproveAdmin(c *fiber.Ctx) error {
	userID, err := strconv.ParseUint(c.Params("id"), 10, 32)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid user ID",
		})
	}

	var user models.User
	if err := models.DB.First(&user, userID).Error; err != nil {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"success": false,
			"message": "User not found",
		})
	}

	if user.Role != models.RoleAdmin {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "User is not an admin",
		})
	}

	if user.IsApproved {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "User is already approved",
		})
	}

	user.IsApproved = true
	if err := models.DB.Save(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to approve admin",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Admin approved successfully",
		"data":    user.ToResponse(),
	})
}

// GetAdmins returns list of all approved admins (for delegation)
func (h *UserHandler) GetAdmins(c *fiber.Ctx) error {
	var users []models.User
	if err := models.DB.Where("(role = ? OR role = ?) AND is_approved = ?",
		models.RoleAdmin, models.RoleSuperAdmin, true).Find(&users).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to fetch admins",
		})
	}

	var responses []models.UserResponse
	for _, user := range users {
		responses = append(responses, user.ToResponse())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    responses,
		"count":   len(responses),
	})
}

// GetAllUsers returns all users (Super-Admin only)
func (h *UserHandler) GetAllUsers(c *fiber.Ctx) error {
	var users []models.User
	if err := models.DB.Find(&users).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to fetch users",
		})
	}

	var responses []models.UserResponse
	for _, user := range users {
		responses = append(responses, user.ToResponse())
	}

	return c.JSON(fiber.Map{
		"success": true,
		"data":    responses,
		"count":   len(responses),
	})
}
