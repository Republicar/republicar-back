CREATE TABLE `expenses` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`description` text NOT NULL,
	`amount` integer NOT NULL,
	`date` integer NOT NULL,
	`republic_id` integer NOT NULL,
	`created_at` integer DEFAULT '"2025-11-28T21:58:55.391Z"' NOT NULL,
	FOREIGN KEY (`republic_id`) REFERENCES `republics`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
PRAGMA foreign_keys=OFF;--> statement-breakpoint
CREATE TABLE `__new_republics` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`address` text NOT NULL,
	`rooms` integer NOT NULL,
	`owner_id` integer NOT NULL,
	`created_at` integer DEFAULT '"2025-11-28T21:58:55.385Z"' NOT NULL,
	FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
INSERT INTO `__new_republics`("id", "name", "address", "rooms", "owner_id", "created_at") SELECT "id", "name", "address", "rooms", "owner_id", "created_at" FROM `republics`;--> statement-breakpoint
DROP TABLE `republics`;--> statement-breakpoint
ALTER TABLE `__new_republics` RENAME TO `republics`;--> statement-breakpoint
PRAGMA foreign_keys=ON;--> statement-breakpoint
CREATE TABLE `__new_users` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`name` text NOT NULL,
	`email` text NOT NULL,
	`password_hash` text NOT NULL,
	`role` text DEFAULT 'OWNER' NOT NULL,
	`republic_id` integer,
	`created_at` integer DEFAULT '"2025-11-28T21:58:55.378Z"' NOT NULL
);
--> statement-breakpoint
INSERT INTO `__new_users`("id", "name", "email", "password_hash", "role", "republic_id", "created_at") SELECT "id", "name", "email", "password_hash", "role", "republic_id", "created_at" FROM `users`;--> statement-breakpoint
DROP TABLE `users`;--> statement-breakpoint
ALTER TABLE `__new_users` RENAME TO `users`;--> statement-breakpoint
CREATE UNIQUE INDEX `users_email_unique` ON `users` (`email`);