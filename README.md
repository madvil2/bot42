# 42 Berlin School Telegram Bot

## Introduction
This Telegram bot is specifically designed for the group chat of 42 students at the Berlin campus, providing automated assistance and information directly relevant to the students' academic and social environment. It is built with Elixir, leveraging the functional programming strengths and concurrency of the Erlang VM, and deployed using Dokku for ease of management and scalability.

## Features

### Commands
- **/today**: Displays today's events from the 42 Berlin school calendar.
- **/events <date>**: Fetches events for a specified date in YYYY-MM-DD or DD.MM.YYYY format.
- **@school42bot <text>**: Direct interaction with ChatGPT for answering queries within the group chat. Limited to 10 requests per day per user.
- **Admin Commands**: Admin-specific commands for managing user permissions and bot settings.

### Technologies
- **Elixir**: A robust language for building scalable and maintainable applications.
- **Dokku**: A Docker-powered mini-Heroku that helps in deploying and managing the application easily.
- **PostgreSQL**: Used for storing user data, admin status, and command logs securely.
- **Ecto**: Elixir's database wrapper that ensures communication between the application and PostgreSQL is efficient and secure.
- **Telegex**: A Telegram bot framework for Elixir that facilitates message handling and bot command processing.

### Admin Features
Admins can add or remove other admins, check logs, and reset daily request counts for users. These features are crucial for maintaining the integrity and smooth operation of the bot within the group.

## Setup
### Prerequisites
- Elixir 1.11+
- PostgreSQL 12+
- Docker
- Dokku

### Deployment
1. **Prepare your Dokku host**: Set up a Dokku instance on your server.
2. **Deploy the Bot**:
   - Push the Elixir application to the Dokku remote.
   - Set environment variables such as `DATABASE_URL` and `TELEGRAM_TOKEN` via Dokku's config management.
   - Ensure the database is properly linked to the application.

## Usage
To interact with the bot, use the provided commands in the Telegram group chat. Admins have additional commands for user management.

## Development
- **Adding Commands**: Extend the bot's functionality by adding new commands in the `Bot42.TgHookHandler` module.
- **Modifying Admin Roles**: Admin roles can be adjusted in the `Bot42.UserRequests` schema.

## Contributing
Contributions to the bot are welcome. Please ensure that all contributions are compliant with the project's code of conduct and follow the pull request guidelines.

## Support
For support or to report issues, contact the developer at Telegram handle @madvil2 or open an issue in the project repository.

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE) file for details.
