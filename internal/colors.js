#!/usr/bin/env node

/* convert hex to ansi */
function hexToRGB(color, prefix, name) {
    var r = parseInt(color.substring(1, 3), 16); // red
    var g = parseInt(color.substring(3, 5), 16); // green
    var b = parseInt(color.substring(5, 7), 16); // blue
    var d = parseInt(color.substring(1, 7), 16); // discord
    return `${prefix}\\e[48;2;${r};${g};${b}m ${name} (${d}) \\e[m`;
}

console.log(hexToRGB('#650021', '\\e[37m', 'maroon'));
console.log(hexToRGB('#653700', '\\e[37m', 'brown'));
console.log(hexToRGB('#6e750e', '\\e[37m', 'olive'));
console.log(hexToRGB('#029386', '\\e[37m', 'teal'));
console.log(hexToRGB('#01153e', '\\e[37m', 'navy'));
console.log(hexToRGB('#000000', '\\e[37m', 'black'));
console.log(hexToRGB('#e50000', '\\e[30m', 'red'));
console.log(hexToRGB('#f97306', '\\e[30m', 'orange'));
console.log(hexToRGB('#ffff14', '\\e[30m', 'yellow'));
console.log(hexToRGB('#aaff32', '\\e[30m', 'lime'));
console.log(hexToRGB('#15b01a', '\\e[30m', 'green'));
console.log(hexToRGB('#00ffff', '\\e[30m', 'cyan'));
console.log(hexToRGB('#0343df', '\\e[30m', 'blue'));
console.log(hexToRGB('#7e1e9c', '\\e[30m', 'purple'));
console.log(hexToRGB('#c20078', '\\e[30m', 'magenta'));
console.log(hexToRGB('#929591', '\\e[30m', 'grey'));
console.log(hexToRGB('#ff81c0', '\\e[30m', 'pink'));
console.log(hexToRGB('#ffb16d', '\\e[30m', 'apricot'));
console.log(hexToRGB('#e6daa6', '\\e[30m', 'beige'));
console.log(hexToRGB('#9ffeb0', '\\e[30m', 'mint'));
console.log(hexToRGB('#c79fef', '\\e[30m', 'lavender'));
console.log(hexToRGB('#ffffff', '\\e[30m', 'white'));
