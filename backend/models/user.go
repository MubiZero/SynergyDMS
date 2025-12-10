package models

import (
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type UserRole string

const (
	RoleStudent    UserRole = "student"
	RoleAdmin      UserRole = "admin"
	RoleSuperAdmin UserRole = "super_admin"
)

type User struct {
	ID         uint           `gorm:"primaryKey" json:"id"`
	Email      string         `gorm:"uniqueIndex;size:255;not null" json:"email"`
	Password   string         `gorm:"size:255;not null" json:"-"`
	FullName   string         `gorm:"size:255;not null" json:"full_name"`
	Role       UserRole       `gorm:"size:50;not null;default:'student'" json:"role"`
	Faculty    string         `gorm:"size:255" json:"faculty"`
	IsApproved bool           `gorm:"default:false" json:"is_approved"`
	CreatedAt  time.Time      `json:"created_at"`
	UpdatedAt  time.Time      `json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index" json:"-"`

	// Relations
	CreatedDocuments  []Document `gorm:"foreignKey:CreatorID" json:"-"`
	AssignedDocuments []Document `gorm:"foreignKey:AssignedToID" json:"-"`
	HistoryActions    []History  `gorm:"foreignKey:ActorID" json:"-"`
}

func (u *User) HashPassword(password string) error {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	u.Password = string(hashedPassword)
	return nil
}

func (u *User) CheckPassword(password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	return err == nil
}

// UserResponse is used to return user data without sensitive information
type UserResponse struct {
	ID         uint     `json:"id"`
	Email      string   `json:"email"`
	FullName   string   `json:"full_name"`
	Role       UserRole `json:"role"`
	Faculty    string   `json:"faculty"`
	IsApproved bool     `json:"is_approved"`
}

func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:         u.ID,
		Email:      u.Email,
		FullName:   u.FullName,
		Role:       u.Role,
		Faculty:    u.Faculty,
		IsApproved: u.IsApproved,
	}
}
