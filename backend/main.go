package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"

	"synergy_dms/config"
	"synergy_dms/handlers"
	"synergy_dms/middleware"
	"synergy_dms/models"
	"synergy_dms/services"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Set JWT secret
	middleware.SetJWTSecret(cfg.JWTSecret)

	// Connect to database
	log.Println("🔌 Connecting to database...")
	if err := models.ConnectDatabase(cfg); err != nil {
		log.Fatalf("❌ Failed to connect to database: %v", err)
	}
	log.Println("✅ Database connected successfully")

	// Run migrations
	log.Println("📦 Running database migrations...")
	if err := models.AutoMigrate(); err != nil {
		log.Fatalf("❌ Failed to run migrations: %v", err)
	}
	log.Println("✅ Migrations completed")

	// Seed super admin
	log.Println("🌱 Seeding initial data...")
	if err := models.SeedSuperAdmin(); err != nil {
		log.Fatalf("❌ Failed to seed super admin: %v", err)
	}

	// Start expiration service
	expirationService := services.NewExpirationService()
	expirationService.Start()

	// Create Fiber app
	app := fiber.New(fiber.Config{
		AppName:      "Synergy DMS v1.0",
		ErrorHandler: customErrorHandler,
		BodyLimit:    50 * 1024 * 1024, // 50MB
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} - ${latency} ${method} ${path}\n",
	}))
	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin,Content-Type,Accept,Authorization",
	}))

	// Static file serving for uploads
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		log.Fatalf("❌ Failed to create uploads directory: %v", err)
	}
	app.Static("/uploads", uploadDir)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(cfg)
	userHandler := handlers.NewUserHandler()
	documentHandler := handlers.NewDocumentHandler()
	uploadHandler := handlers.NewUploadHandler(uploadDir)

	// Routes
	setupRoutes(app, authHandler, userHandler, documentHandler, uploadHandler)

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan

		log.Println("🛑 Shutting down server...")
		expirationService.Stop()
		app.Shutdown()
	}()

	// Start server
	serverAddr := fmt.Sprintf(":%s", cfg.ServerPort)
	log.Printf("🚀 Server starting on http://localhost%s", serverAddr)
	log.Println("📝 API Documentation:")
	log.Println("   - POST /auth/register - Register new user")
	log.Println("   - POST /auth/login - Login")
	log.Println("   - GET  /users/pending-admins - Get pending admins (Super-Admin)")
	log.Println("   - PUT  /users/:id/approve - Approve admin (Super-Admin)")
	log.Println("   - GET  /users/admins - Get all admins")
	log.Println("   - GET  /documents - Get documents")
	log.Println("   - POST /documents - Create document")
	log.Println("   - PUT  /documents/:id/status - Update status")
	log.Println("   - PUT  /documents/:id/delegate - Delegate document")
	log.Println("   - GET  /documents/:id/history - Get history")
	log.Println("   - POST /api/upload - Upload file")

	if err := app.Listen(serverAddr); err != nil {
		log.Fatalf("❌ Server failed to start: %v", err)
	}
}

func setupRoutes(app *fiber.App, authHandler *handlers.AuthHandler, userHandler *handlers.UserHandler,
	documentHandler *handlers.DocumentHandler, uploadHandler *handlers.UploadHandler) {

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status":  "healthy",
			"service": "Synergy DMS",
			"version": "1.0.0",
		})
	})

	// Auth routes (public)
	auth := app.Group("/auth")
	auth.Post("/register", authHandler.Register)
	auth.Post("/login", authHandler.Login)

	// Protected routes
	api := app.Group("/", middleware.AuthRequired())

	// Profile
	api.Get("auth/profile", authHandler.GetProfile)

	// User routes
	users := api.Group("/users")
	users.Get("/pending-admins", middleware.SuperAdminOnly(), userHandler.GetPendingAdmins)
	users.Put("/:id/approve", middleware.SuperAdminOnly(), userHandler.ApproveAdmin)
	users.Get("/admins", userHandler.GetAdmins)
	users.Get("/", middleware.SuperAdminOnly(), userHandler.GetAllUsers)

	// Document routes
	documents := api.Group("/documents")
	documents.Get("/", documentHandler.GetDocuments)
	documents.Post("/", documentHandler.CreateDocument)
	documents.Get("/:id", documentHandler.GetDocument)
	documents.Put("/:id/status", middleware.AdminOrSuperAdmin(), documentHandler.UpdateDocumentStatus)
	documents.Put("/:id/delegate", middleware.AdminOrSuperAdmin(), documentHandler.DelegateDocument)
	documents.Get("/:id/history", documentHandler.GetDocumentHistory)

	// Upload route
	upload := api.Group("/api")
	upload.Post("/upload", uploadHandler.UploadFile)
}

func customErrorHandler(c *fiber.Ctx, err error) error {
	code := fiber.StatusInternalServerError

	if e, ok := err.(*fiber.Error); ok {
		code = e.Code
	}

	return c.Status(code).JSON(fiber.Map{
		"success": false,
		"message": err.Error(),
	})
}
