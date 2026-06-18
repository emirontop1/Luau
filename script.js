const input = document.querySelector('#input');
const output = document.querySelector('#output');
const preset = document.querySelector('#preset');
const button = document.querySelector('#obfuscate');

const encodeString = (value) => 'string.char(' + [...value].map((char) => char.charCodeAt(0)).join(',') + ')';

function obfuscateLua(source, mode) {
  let code = source
    .replace(/--\[\[[\s\S]*?\]\]/g, '')
    .replace(/--.*$/gm, '')
    .replace(/"([^"\\]*(?:\\.[^"\\]*)*)"|'([^'\\]*(?:\\.[^'\\]*)*)'/g, (_, doubleValue, singleValue) => encodeString(doubleValue ?? singleValue ?? ''));

  const names = [...new Set([...code.matchAll(/\blocal\s+([A-Za-z_][A-Za-z0-9_]*)/g)].map((match) => match[1]))];
  names.forEach((name, index) => {
    code = code.replace(new RegExp(`\\b${name}\\b`, 'g'), `_LB_${(index + 1).toString(36)}_${mode}`);
  });

  if (mode !== 'light') code = code.replace(/\s+/g, ' ').trim();
  const noise = mode === 'bank' ? 'local _LuaBankRelease=true; ' : mode === 'heavy' ? 'local _LB_WATERMARK="LuaBank"; ' : '';
  return `--[[ Protected by LuaBank Obfuscator | preset=${mode} ]]\n${noise}${code}`;
}

button.addEventListener('click', () => {
  output.value = obfuscateLua(input.value, preset.value);
  output.focus();
  output.select();
});

button.click();
