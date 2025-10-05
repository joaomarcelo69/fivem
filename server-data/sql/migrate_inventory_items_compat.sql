-- Migration: align inventory_items columns with resource usage
ALTER TABLE inventory_items
  ADD COLUMN IF NOT EXISTS inventory_id VARCHAR(128) NULL,
  ADD COLUMN IF NOT EXISTS item VARCHAR(128) NULL;

-- Backfill from legacy columns if present
UPDATE inventory_items
SET inventory_id = COALESCE(inventory_id, inventory_name),
    item = COALESCE(item, item_name)
WHERE (inventory_id IS NULL OR item IS NULL);

-- Add unique composite key for upsert logic
ALTER TABLE inventory_items
  ADD UNIQUE KEY IF NOT EXISTS uniq_inventory_item (inventory_id, item);
