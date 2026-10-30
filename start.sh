#!/usr/bin/env bash

echo "
            ┏┳┓╋┏┓╋╋╋╋┏┓┏┓
            ┃┃┣┓┃┗┳┳┳━╋╋┛┃
            ┃┃┃┗┫┏┫┏┫╋┃┃╋┃
            ┗━┻━┻━┻┛┗━┻┻━┛

      Visit @TheUltroid for updates!!

"
export TIMEZONE="UTC" 
git config --global user.name "kailashhh"
git config --global user.email "alex.c992954@gmail.xom"

git config --global --add safe.directory /Ult

# Fix 4: Handle Unknown Time Zone
if [ -z "$(python3 -c 'import pytz; print(pytz.timezone("UTC"))')" ]; then
  echo "Error: Timezone is invalid or not set. Using UTC as default."
  export TIMEZONE="UTC"
fi

# Fix 5: Ensure Permissions on .gitconfig
if [ ! -w ~/.gitconfig ]; then
  echo "Error: Insufficient permissions for .gitconfig. Fixing..."
  sudo chmod 644 ~/.gitconfig
fi

# Run the setup/status + keep-alive server in the background.
python3 server.py &

# Print Success Message
echo "Git setup and server initialized successfully."

if [ -f .env ] ; then  set -o allexport; source .env; set +o allexport ; fi
# Run the bot in the foreground so it starts automatically on every restart.
if [ -n "${SESSION1:-}" ] ; then
  python3 multi_session.py
else
  python3 -m pyUltroid
fi
