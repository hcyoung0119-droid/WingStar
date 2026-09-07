import { sqliteTable, text, integer, primaryKey, uniqueIndex, index } from 'drizzle-orm/sqlite-core';
export const users = sqliteTable('social_users', {
  id:text('id').primaryKey(), subject:text('subject').notNull(), publicId:text('public_id').notNull(),
  nickname:text('nickname').notNull(), accent:text('accent').notNull().default('sky'), badge:text('badge').notNull().default('leaf'),
  publicRanking:integer('public_ranking').notNull().default(0), createdAt:integer('created_at').notNull(),
}, t => [uniqueIndex('users_subject_unique').on(t.subject), uniqueIndex('users_public_id_unique').on(t.publicId)]);
export const sessions = sqliteTable('social_sessions', {
  tokenHash:text('token_hash').primaryKey(), userId:text('user_id').notNull().references(()=>users.id,{onDelete:'cascade'}), expiresAt:integer('expires_at').notNull(),
}, t => [index('sessions_expiry').on(t.expiresAt)]);
export const challenges = sqliteTable('social_login_challenges', {
  nonceHash:text('nonce_hash').primaryKey(), expiresAt:integer('expires_at').notNull(),
});
export const friendships = sqliteTable('social_friendships', {
  low:text('user_low').notNull().references(()=>users.id,{onDelete:'cascade'}),
  high:text('user_high').notNull().references(()=>users.id,{onDelete:'cascade'}),
  requestedBy:text('requested_by').notNull().references(()=>users.id,{onDelete:'cascade'}),
  status:text('status').notNull().default('pending'), createdAt:integer('created_at').notNull(),
}, t => [primaryKey({columns:[t.low,t.high]}),index('friendships_high_status').on(t.high,t.status)]);
export const activities = sqliteTable('social_activity_batches', {
  id:text('id').primaryKey(), userId:text('user_id').notNull().references(()=>users.id,{onDelete:'cascade'}),
  day:text('day').notNull(), steps:integer('steps').notNull(), recordedAt:integer('recorded_at').notNull(),
}, t => [index('activities_user_day').on(t.userId,t.day)]);
export const cheers = sqliteTable('social_cheers', {
  from:text('from_user').notNull().references(()=>users.id,{onDelete:'cascade'}),
  to:text('to_user').notNull().references(()=>users.id,{onDelete:'cascade'}), day:text('day').notNull(),
}, t => [primaryKey({columns:[t.from,t.to,t.day]})]);
