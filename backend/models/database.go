package models

import (
	"fmt"
	"log"
	"time"

	"synergy_dms/config"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

func ConnectDatabase(cfg *config.Config) error {
	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=UTC",
		cfg.DBHost, cfg.DBUser, cfg.DBPassword, cfg.DBName, cfg.DBPort,
	)

	var db *gorm.DB
	var err error

	// Retry connection up to 30 times (waiting for postgres to be ready)
	maxRetries := 30
	for i := 0; i < maxRetries; i++ {
		db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{
			Logger: logger.Default.LogMode(logger.Info),
		})
		if err == nil {
			break
		}
		log.Printf("Failed to connect to database (attempt %d/%d): %v", i+1, maxRetries, err)
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		return fmt.Errorf("failed to connect to database after %d attempts: %w", maxRetries, err)
	}

	// Configure connection pool
	sqlDB, err := db.DB()
	if err != nil {
		return fmt.Errorf("failed to get sql.DB: %w", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	DB = db
	return nil
}

func AutoMigrate() error {
	return DB.AutoMigrate(&User{}, &Document{}, &History{})
}

func SeedSuperAdmin() error {
	var count int64
	DB.Model(&User{}).Count(&count)

	if count == 0 {
		superAdmin := User{
			Email:      "super@synergy.ru",
			FullName:   "Super Administrator",
			Role:       RoleSuperAdmin,
			Faculty:    "Administration",
			IsApproved: true,
		}

		if err := superAdmin.HashPassword("123456"); err != nil {
			return fmt.Errorf("failed to hash password: %w", err)
		}

		if err := DB.Create(&superAdmin).Error; err != nil {
			return fmt.Errorf("failed to create super admin: %w", err)
		}

		log.Println("✅ Super Admin created: super@synergy.ru / 123456")
	}

	return nil
}
