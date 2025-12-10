package middleware

import (
	"strings"
	"time"

	"synergy_dms/config"
	"synergy_dms/models"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
)

type JWTClaims struct {
	UserID uint            `json:"user_id"`
	Email  string          `json:"email"`
	Role   models.UserRole `json:"role"`
	jwt.RegisteredClaims
}

var jwtSecret []byte

func SetJWTSecret(secret string) {
	jwtSecret = []byte(secret)
}

func GenerateToken(user *models.User, cfg *config.Config) (string, error) {
	claims := JWTClaims{
		UserID: user.ID,
		Email:  user.Email,
		Role:   user.Role,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "synergy_dms",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(cfg.JWTSecret))
}

func AuthRequired() fiber.Handler {
	return func(c *fiber.Ctx) error {
		authHeader := c.Get("Authorization")
		if authHeader == "" {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Missing authorization header",
			})
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid authorization header format",
			})
		}

		token, err := jwt.ParseWithClaims(tokenString, &JWTClaims{}, func(token *jwt.Token) (interface{}, error) {
			return jwtSecret, nil
		})

		if err != nil || !token.Valid {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid or expired token",
			})
		}

		claims, ok := token.Claims.(*JWTClaims)
		if !ok {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "Invalid token claims",
			})
		}

		// Check if user is approved (for admins)
		var user models.User
		if err := models.DB.First(&user, claims.UserID).Error; err != nil {
			return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
				"success": false,
				"message": "User not found",
			})
		}

		if !user.IsApproved {
			return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
				"success": false,
				"message": "Your account is pending approval",
			})
		}

		// Store user info in context
		c.Locals("userID", claims.UserID)
		c.Locals("userEmail", claims.Email)
		c.Locals("userRole", claims.Role)
		c.Locals("user", &user)

		return c.Next()
	}
}

func RoleRequired(roles ...models.UserRole) fiber.Handler {
	return func(c *fiber.Ctx) error {
		userRole := c.Locals("userRole").(models.UserRole)

		for _, role := range roles {
			if userRole == role {
				return c.Next()
			}
		}

		return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
			"success": false,
			"message": "Insufficient permissions",
		})
	}
}

func AdminOrSuperAdmin() fiber.Handler {
	return RoleRequired(models.RoleAdmin, models.RoleSuperAdmin)
}

func SuperAdminOnly() fiber.Handler {
	return RoleRequired(models.RoleSuperAdmin)
}
