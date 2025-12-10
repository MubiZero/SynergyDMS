package handlers

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/google/uuid"
)

type UploadHandler struct {
	UploadDir string
}

func NewUploadHandler(uploadDir string) *UploadHandler {
	// Ensure upload directory exists
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		panic(fmt.Sprintf("Failed to create upload directory: %v", err))
	}
	return &UploadHandler{UploadDir: uploadDir}
}

func (h *UploadHandler) UploadFile(c *fiber.Ctx) error {
	file, err := c.FormFile("file")
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "No file uploaded",
		})
	}

	// Validate file size (max 50MB)
	maxSize := int64(50 * 1024 * 1024)
	if file.Size > maxSize {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "File size exceeds 50MB limit",
		})
	}

	// Validate file extension
	allowedExtensions := map[string]bool{
		".pdf":  true,
		".doc":  true,
		".docx": true,
		".xls":  true,
		".xlsx": true,
		".ppt":  true,
		".pptx": true,
		".txt":  true,
		".png":  true,
		".jpg":  true,
		".jpeg": true,
		".gif":  true,
		".zip":  true,
		".rar":  true,
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !allowedExtensions[ext] {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "File type not allowed",
		})
	}

	// Generate unique filename
	uniqueID := uuid.New().String()
	timestamp := time.Now().Format("20060102_150405")
	newFilename := fmt.Sprintf("%s_%s%s", timestamp, uniqueID[:8], ext)

	// Save file
	filePath := filepath.Join(h.UploadDir, newFilename)
	if err := c.SaveFile(file, filePath); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to save file",
		})
	}

	// Return URL path
	fileURL := "/uploads/" + newFilename

	return c.JSON(fiber.Map{
		"success": true,
		"message": "File uploaded successfully",
		"data": fiber.Map{
			"filename":      newFilename,
			"original_name": file.Filename,
			"size":          file.Size,
			"url":           fileURL,
		},
	})
}
