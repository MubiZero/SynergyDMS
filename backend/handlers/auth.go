package handlers

import (
	"synergy_dms/config"
	"synergy_dms/middleware"
	"synergy_dms/models"

	"github.com/gofiber/fiber/v2"
)

type AuthHandler struct {
	Config *config.Config
}

func NewAuthHandler(cfg *config.Config) *AuthHandler {
	return &AuthHandler{Config: cfg}
}

type RegisterRequest struct {
	Email    string          `json:"email"`
	Password string          `json:"password"`
	FullName string          `json:"full_name"`
	Role     models.UserRole `json:"role"`
	Faculty  string          `json:"faculty"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *AuthHandler) Register(c *fiber.Ctx) error {
	var req RegisterRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	// Validate required fields
	if req.Email == "" || req.Password == "" || req.FullName == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Email, password, and full name are required",
		})
	}

	// Validate role
	if req.Role == "" {
		req.Role = models.RoleStudent
	}

	if req.Role != models.RoleStudent && req.Role != models.RoleAdmin {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid role. Must be 'student' or 'admin'",
		})
	}

	// Check if email already exists
	var existingUser models.User
	if err := models.DB.Where("email = ?", req.Email).First(&existingUser).Error; err == nil {
		return c.Status(fiber.StatusConflict).JSON(fiber.Map{
			"success": false,
			"message": "Email already registered",
		})
	}

	// Create user
	user := models.User{
		Email:    req.Email,
		FullName: req.FullName,
		Role:     req.Role,
		Faculty:  req.Faculty,
	}

	// Set IsApproved based on role
	if req.Role == models.RoleStudent {
		user.IsApproved = true
	} else {
		user.IsApproved = false // Admins need Super-Admin approval
	}

	// Hash password
	if err := user.HashPassword(req.Password); err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to process password",
		})
	}

	// Save user
	if err := models.DB.Create(&user).Error; err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to create user",
		})
	}

	// Generate token
	token, err := middleware.GenerateToken(&user, h.Config)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to generate token",
		})
	}

	return c.Status(fiber.StatusCreated).JSON(fiber.Map{
		"success": true,
		"message": "Registration successful",
		"data": fiber.Map{
			"user":  user.ToResponse(),
			"token": token,
		},
	})
}

func (h *AuthHandler) Login(c *fiber.Ctx) error {
	var req LoginRequest
	if err := c.BodyParser(&req); err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Invalid request body",
		})
	}

	if req.Email == "" || req.Password == "" {
		return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
			"success": false,
			"message": "Email and password are required",
		})
	}

	// Find user
	var user models.User
	if err := models.DB.Where("email = ?", req.Email).First(&user).Error; err != nil {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": "Invalid email or password",
		})
	}

	// Check password
	if !user.CheckPassword(req.Password) {
		return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
			"success": false,
			"message": "Invalid email or password",
		})
	}

	// Generate token
	token, err := middleware.GenerateToken(&user, h.Config)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
			"success": false,
			"message": "Failed to generate token",
		})
	}

	return c.JSON(fiber.Map{
		"success": true,
		"message": "Login successful",
		"data": fiber.Map{
			"user":  user.ToResponse(),
			"token": token,
		},
	})
}

func (h *AuthHandler) GetProfile(c *fiber.Ctx) error {
	user := c.Locals("user").(*models.User)

	return c.JSON(fiber.Map{
		"success": true,
		"data":    user.ToResponse(),
	})
}
