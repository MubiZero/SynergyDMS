package models

import (
	"time"

	"gorm.io/gorm"
)

type DocumentStatus string
type DocumentPriority int

const (
	StatusPending  DocumentStatus = "pending"
	StatusApproved DocumentStatus = "approved"
	StatusRejected DocumentStatus = "rejected"
	StatusExpired  DocumentStatus = "expired"
)

const (
	PriorityLow    DocumentPriority = 1
	PriorityMedium DocumentPriority = 2
	PriorityHigh   DocumentPriority = 3
)

type Document struct {
	ID              uint             `gorm:"primaryKey" json:"id"`
	Title           string           `gorm:"size:255;not null" json:"title"`
	Description     string           `gorm:"type:text" json:"description"`
	FilePath        string           `gorm:"size:500" json:"file_path"`
	Priority        DocumentPriority `gorm:"default:1" json:"priority"`
	Status          DocumentStatus   `gorm:"size:50;default:'pending'" json:"status"`
	RejectionReason string           `gorm:"type:text" json:"rejection_reason,omitempty"`
	Deadline        *time.Time       `json:"deadline,omitempty"`
	CreatorID       uint             `gorm:"not null" json:"creator_id"`
	AssignedToID    *uint            `json:"assigned_to_id,omitempty"`
	CreatedAt       time.Time        `json:"created_at"`
	UpdatedAt       time.Time        `json:"updated_at"`
	DeletedAt       gorm.DeletedAt   `gorm:"index" json:"-"`

	// Relations
	Creator    User      `gorm:"foreignKey:CreatorID" json:"creator,omitempty"`
	AssignedTo *User     `gorm:"foreignKey:AssignedToID" json:"assigned_to,omitempty"`
	History    []History `gorm:"foreignKey:DocumentID" json:"history,omitempty"`
}

type DocumentResponse struct {
	ID              uint             `json:"id"`
	Title           string           `json:"title"`
	Description     string           `json:"description"`
	FilePath        string           `json:"file_path"`
	Priority        DocumentPriority `json:"priority"`
	Status          DocumentStatus   `json:"status"`
	RejectionReason string           `json:"rejection_reason,omitempty"`
	Deadline        *time.Time       `json:"deadline,omitempty"`
	CreatorID       uint             `json:"creator_id"`
	AssignedToID    *uint            `json:"assigned_to_id,omitempty"`
	CreatorName     string           `json:"creator_name,omitempty"`
	AssignedToName  string           `json:"assigned_to_name,omitempty"`
	CreatedAt       time.Time        `json:"created_at"`
	UpdatedAt       time.Time        `json:"updated_at"`
}

func (d *Document) ToResponse() DocumentResponse {
	resp := DocumentResponse{
		ID:              d.ID,
		Title:           d.Title,
		Description:     d.Description,
		FilePath:        d.FilePath,
		Priority:        d.Priority,
		Status:          d.Status,
		RejectionReason: d.RejectionReason,
		Deadline:        d.Deadline,
		CreatorID:       d.CreatorID,
		AssignedToID:    d.AssignedToID,
		CreatedAt:       d.CreatedAt,
		UpdatedAt:       d.UpdatedAt,
	}

	if d.Creator.ID != 0 {
		resp.CreatorName = d.Creator.FullName
	}

	if d.AssignedTo != nil && d.AssignedTo.ID != 0 {
		resp.AssignedToName = d.AssignedTo.FullName
	}

	return resp
}
