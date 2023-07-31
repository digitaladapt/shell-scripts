#!/bin/bash

# this only works if your crontab uses three spaces for each section,
# like the following spacing example:
#m  h   dom mon dow command

# quickly generate a script file which will run each crontab task
# optionally takes filename to use, otherwise defaults 'crontasks.sh'
FILENAME="$1"

if [ -z "$FILENAME" ]; then
    FILENAME='crontasks.sh'
fi

echo "#!/bin/bash\n" > "$FILENAME"

# list crontab, remove comments and empty lines,
# expect cron time formatting to be the first 20 characters,
# so drop the 21st character onward to standard out.
crontab -l | grep -Ev '^(#|$)' | cut -c 21- >> "$FILENAME"

chmod +x "$FILENAME"

