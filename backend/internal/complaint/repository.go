package complaint

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	DB *pgxpool.Pool
}

func (r *Repository) CreateComplaint(
	ctx context.Context,
	citizenID string,
	req CreateComplaintRequest,
) (string, error) {

	locationJSON, _ := json.Marshal(req.Location)

	var complaintID string

	err := r.DB.QueryRow(ctx,
		`INSERT INTO complaints
		(citizen_id, category, severity, latitude, longitude, street, area, ward, city, location_json, image_url)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
		RETURNING id`,
		citizenID,
		req.Category,
		req.Severity,
		req.Latitude,
		req.Longitude,
		req.Street,
		req.Area,
		req.Ward,
		req.City,
		locationJSON,
		req.ImageURL,
	).Scan(&complaintID)

	return complaintID, err
}

func (r *Repository) GetComplaintsByCitizen(ctx context.Context, citizenID string) ([]Complaint, error) {
	rows, err := r.DB.Query(ctx,
		`SELECT id, category, severity, COALESCE(latitude, 0), COALESCE(longitude, 0), 
		        COALESCE(street, ''), COALESCE(area, ''), COALESCE(ward, ''), COALESCE(city, ''), 
		        status, created_at, COALESCE(image_url, ''), COALESCE(location_json, '{}'::jsonb),
		        COALESCE(rating, 0), COALESCE(feedback_text, '')
		 FROM complaints 
		 WHERE citizen_id=$1 
		 ORDER BY created_at DESC`,
		citizenID)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var complaints []Complaint
	for rows.Next() {
		var c Complaint
		var locationJSON []byte

		err := rows.Scan(
			&c.ID, &c.Category, &c.Severity, &c.Latitude, &c.Longitude,
			&c.Street, &c.Area, &c.Ward, &c.City,
			&c.Status, &c.CreatedAt, &c.ImageURL, &locationJSON,
			&c.Rating, &c.FeedbackText,
		)
		if err != nil {
			return nil, err
		}

		_ = json.Unmarshal(locationJSON, &c.Location)
		complaints = append(complaints, c)
	}

	return complaints, nil
}

func (r *Repository) UpdateFeedback(ctx context.Context, citizenID, complaintID string, rating int, feedback string) error {
	_, err := r.DB.Exec(ctx,
		`UPDATE complaints 
		 SET rating = $1, feedback_text = $2 
		 WHERE id = $3 AND citizen_id = $4 AND status = 'COMPLETED'`,
		rating, feedback, complaintID, citizenID,
	)
	return err
}
