package models

import (
	"time"
)

type ActionType string

const (
	ActionCreated   ActionType = "Created"
	ActionApproved  ActionType = "Approved"
	ActionRejected  ActionType = "Rejected"
	ActionDelegated ActionType = "Delegated"
	ActionExpired   ActionType = "Expired"
)

type History struct {
	ID         uint       `gorm:"primaryKey" json:"id"`
	DocumentID uint       `gorm:"not null;index" json:"document_id"`
	ActorID    uint       `gorm:"not null" json:"actor_id"`
	Action     ActionType `gorm:"size:50;not null" json:"action"`
	Comment    string     `gorm:"type:text" json:"comment,omitempty"`
	Timestamp  time.Time  `gorm:"autoCreateTime" json:"timestamp"`

	// Relations
	Document Document `gorm:"foreignKey:DocumentID" json:"-"`
	Actor    User     `gorm:"foreignKey:ActorID" json:"actor,omitempty"`
}

type HistoryResponse struct {
	ID         uint       `json:"id"`
	DocumentID uint       `json:"document_id"`
	ActorID    uint       `json:"actor_id"`
	ActorName  string     `json:"actor_name"`
	Action     ActionType `json:"action"`
	Comment    string     `json:"comment,omitempty"`
	Timestamp  time.Time  `json:"timestamp"`
}

func (h *History) ToResponse() HistoryResponse {
	return HistoryResponse{
		ID:         h.ID,
		DocumentID: h.DocumentID,
		ActorID:    h.ActorID,
		ActorName:  h.Actor.FullName,
		Action:     h.Action,
		Comment:    h.Comment,
		Timestamp:  h.Timestamp,
	}
}
