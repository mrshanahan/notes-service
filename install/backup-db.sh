#!/usr/bin/env bash

NOTES_DB_SRC="/var/lib/docker/volumes/notes-data/_data/notes.sqlite"
BACKUP_DST="s3://quemot-dev-bucket/notes-db-backups"
aws s3 cp "$NOTES_DB_SRC" "$BACKUP_DST/notes_backup_$(date -u +%Y%m%d_%H%M%SZ).sqlite"