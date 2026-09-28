# Blackout City database

The game uses Supabase PostgreSQL as its shared online database.

## Setup

1. Open the Supabase project.
2. Go to **SQL Editor**.
3. Run `schema.sql` completely.
4. In **Authentication -> Users**, create the 21 game accounts:
   - `user01@blackoutcity.local` through `user20@blackoutcity.local`
   - `admin@blackoutcity.local`
5. Use the passwords you want for those accounts. The game accepts the username part (`user01`, `user02`, etc.) and converts it to the email internally.
6. Publish the HTML on GitHub Pages.

## Security

Never put a Supabase `sb_secret_...` / service-role key in the website. The game only contains the publishable key. Row Level Security limits each player to their own save and leaderboard write, while leaderboard reads are public.

## What is stored

- `player_saves`: complete per-player game state as JSON.
- `leaderboard`: public leaderboard fields such as display name, level, net worth and wins.

The website automatically upserts both records after gameplay changes.
