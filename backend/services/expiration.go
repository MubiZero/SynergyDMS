package services

import (
	"log"
	"time"

	"synergy_dms/models"
)

type ExpirationService struct {
	ticker *time.Ticker
	done   chan bool
}

func NewExpirationService() *ExpirationService {
	return &ExpirationService{
		done: make(chan bool),
	}
}

// Start begins the background job to expire old pending documents
func (s *ExpirationService) Start() {
	s.ticker = time.NewTicker(1 * time.Hour) // Run every hour

	go func() {
		// Run immediately on start
		s.checkAndExpireDocuments()

		for {
			select {
			case <-s.done:
				return
			case <-s.ticker.C:
				s.checkAndExpireDocuments()
			}
		}
	}()

	log.Println("📅 Expiration service started (checking every 1 hour)")
}

// Stop gracefully stops the background service
func (s *ExpirationService) Stop() {
	if s.ticker != nil {
		s.ticker.Stop()
	}
	s.done <- true
	log.Println("📅 Expiration service stopped")
}

func (s *ExpirationService) checkAndExpireDocuments() {
	log.Println("🔍 Checking for expired documents...")

	// Find pending documents older than 7 days
	sevenDaysAgo := time.Now().AddDate(0, 0, -7)

	var documents []models.Document
	result := models.DB.Where("status = ? AND created_at < ?", models.StatusPending, sevenDaysAgo).Find(&documents)

	if result.Error != nil {
		log.Printf("❌ Error fetching documents for expiration: %v", result.Error)
		return
	}

	if len(documents) == 0 {
		log.Println("✅ No documents to expire")
		return
	}

	log.Printf("⏰ Found %d documents to expire", len(documents))

	for _, doc := range documents {
		// Update status to expired
		doc.Status = models.StatusExpired
		if err := models.DB.Save(&doc).Error; err != nil {
			log.Printf("❌ Failed to expire document %d: %v", doc.ID, err)
			continue
		}

		// Create history entry (using system actor ID 0 or the super admin)
		var superAdmin models.User
		models.DB.Where("role = ?", models.RoleSuperAdmin).First(&superAdmin)

		actorID := superAdmin.ID
		if actorID == 0 {
			actorID = 1 // Fallback to ID 1
		}

		history := models.History{
			DocumentID: doc.ID,
			ActorID:    actorID,
			Action:     models.ActionExpired,
			Comment:    "Document automatically expired after 7 days of pending status",
		}

		if err := models.DB.Create(&history).Error; err != nil {
			log.Printf("❌ Failed to create history for expired document %d: %v", doc.ID, err)
		} else {
			log.Printf("✅ Document %d (%s) expired successfully", doc.ID, doc.Title)
		}
	}
}
