CREATE TABLE `social_activity_batches` (
	`id` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`day` text NOT NULL,
	`steps` integer NOT NULL,
	`recorded_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `activities_user_day` ON `social_activity_batches` (`user_id`,`day`);--> statement-breakpoint
CREATE TABLE `social_login_challenges` (
	`nonce_hash` text PRIMARY KEY NOT NULL,
	`expires_at` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `social_cheers` (
	`from_user` text NOT NULL,
	`to_user` text NOT NULL,
	`day` text NOT NULL,
	PRIMARY KEY(`from_user`, `to_user`, `day`),
	FOREIGN KEY (`from_user`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`to_user`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE TABLE `social_friendships` (
	`user_low` text NOT NULL,
	`user_high` text NOT NULL,
	`requested_by` text NOT NULL,
	`status` text DEFAULT 'pending' NOT NULL,
	`created_at` integer NOT NULL,
	PRIMARY KEY(`user_low`, `user_high`),
	FOREIGN KEY (`user_low`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`user_high`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade,
	FOREIGN KEY (`requested_by`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `friendships_high_status` ON `social_friendships` (`user_high`,`status`);--> statement-breakpoint
CREATE TABLE `social_sessions` (
	`token_hash` text PRIMARY KEY NOT NULL,
	`user_id` text NOT NULL,
	`expires_at` integer NOT NULL,
	FOREIGN KEY (`user_id`) REFERENCES `social_users`(`id`) ON UPDATE no action ON DELETE cascade
);
--> statement-breakpoint
CREATE INDEX `sessions_expiry` ON `social_sessions` (`expires_at`);--> statement-breakpoint
CREATE TABLE `social_users` (
	`id` text PRIMARY KEY NOT NULL,
	`subject` text NOT NULL,
	`public_id` text NOT NULL,
	`nickname` text NOT NULL,
	`accent` text DEFAULT 'sky' NOT NULL,
	`badge` text DEFAULT 'leaf' NOT NULL,
	`public_ranking` integer DEFAULT 0 NOT NULL,
	`created_at` integer NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `users_subject_unique` ON `social_users` (`subject`);--> statement-breakpoint
CREATE UNIQUE INDEX `users_public_id_unique` ON `social_users` (`public_id`);