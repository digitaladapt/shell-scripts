#!/bin/bash

# quickly generate a script file which will contain all crontab tasks.
# optionally takes filename to use, defaults to 'crontasks.sh'.
crontasks="$1"

if [[ -z "$crontasks" ]]; then
    crontasks='crontasks.sh'
fi

# prefix file we are generating
echo "#!/bin/bash" > "$crontasks"
echo "" >> "$crontasks"

# list crontab, remove comments, convert tabs to space, squeeze the spaces,
# then take the sixth field "command" and add it to the file.
# could have issues if a task has a "#" in the middle.
crontab -l | grep -o '^[^#]*' | tr "\t" ' ' | tr -s ' ' | cut -s -d ' ' -f 6- >> "$crontasks"

echo "" >> "$crontasks"

# make the file executable, so we are good to go
chmod +x "$crontasks"

