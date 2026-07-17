const assert = require("assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const vm = require("vm");

const project = path.resolve(__dirname, "..");
const html = fs.readFileSync(path.join(project, "launcher", "Plugcade.hta"), "utf8");
const scripts = [...html.matchAll(/<script language="JScript">([\s\S]*?)<\/script>/ig)].map((m) => m[1]);
assert.equal(scripts.length, 3, "expected base plus two Core 0.4 script blocks");
new Function(scripts.join("\n"));

const temp = fs.mkdtempSync(path.join(os.tmpdir(), "plugcade-test-"));
const virtualRoot = "X:\\Plugcade";
const realRoot = path.join(temp, "Plugcade");
fs.mkdirSync(realRoot, { recursive: true });

function toReal(value) {
  let s = String(value);
  if (s.toLowerCase().startsWith(virtualRoot.toLowerCase())) s = realRoot + s.slice(virtualRoot.length);
  return s.replace(/\\/g, path.sep);
}
function toVirtual(value) {
  const real = path.resolve(String(value));
  if (real.toLowerCase().startsWith(realRoot.toLowerCase())) {
    return virtualRoot + real.slice(realRoot.length).split(path.sep).join("\\");
  }
  return real.split(path.sep).join("\\");
}
function copyDir(src, dst, overwrite) {
  if (fs.existsSync(dst) && !overwrite) throw new Error("destination exists");
  fs.mkdirSync(dst, { recursive: true });
  for (const entry of fs.readdirSync(src, { withFileTypes: true })) {
    const a = path.join(src, entry.name), b = path.join(dst, entry.name);
    if (entry.isDirectory()) copyDir(a, b, overwrite);
    else if (!fs.existsSync(b) || overwrite) fs.copyFileSync(a, b);
  }
}
class TextStream {
  constructor(file, mode, create) {
    this.file = toReal(file); this.mode = mode; this.lines = []; this.pos = 0; this.buffer = "";
    if (mode === 1) {
      const text = fs.readFileSync(this.file, "utf8");
      this.all = text; this.lines = text.replace(/\r/g, "").split("\n");
      if (this.lines.length && this.lines[this.lines.length - 1] === "") this.lines.pop();
    } else {
      fs.mkdirSync(path.dirname(this.file), { recursive: true });
      if (mode === 8 && fs.existsSync(this.file)) this.buffer = fs.readFileSync(this.file, "utf8");
      else if (!create && !fs.existsSync(this.file)) throw new Error("file missing");
    }
  }
  get AtEndOfStream() { return this.pos >= this.lines.length; }
  ReadLine() { return this.lines[this.pos++]; }
  ReadAll() { this.pos = this.lines.length; return this.all; }
  WriteLine(value) { this.buffer += String(value) + "\r\n"; }
  Write(value) { this.buffer += String(value); }
  Close() { if (this.mode !== 1) fs.writeFileSync(this.file, this.buffer); }
}
class FileObject {
  constructor(real) { this.real = real; }
  get Path() { return toVirtual(this.real); }
  get Name() { return path.basename(this.real); }
  get Size() { return fs.statSync(this.real).size; }
}
class FolderObject {
  constructor(real) { this.real = real; }
  get Path() { return toVirtual(this.real); }
  get Name() { return path.basename(this.real); }
  get Files() { return fs.readdirSync(this.real, { withFileTypes: true }).filter((x) => x.isFile()).map((x) => new FileObject(path.join(this.real, x.name))); }
  get SubFolders() { return fs.readdirSync(this.real, { withFileTypes: true }).filter((x) => x.isDirectory()).map((x) => new FolderObject(path.join(this.real, x.name))); }
}
class Enumerator {
  constructor(items) { this.items = Array.from(items || []); this.index = 0; }
  atEnd() { return this.index >= this.items.length; }
  moveNext() { this.index++; }
  item() { return this.items[this.index]; }
}
class FSO {
  FolderExists(p) { return fs.existsSync(toReal(p)) && fs.statSync(toReal(p)).isDirectory(); }
  FileExists(p) { return fs.existsSync(toReal(p)) && fs.statSync(toReal(p)).isFile(); }
  CreateFolder(p) { fs.mkdirSync(toReal(p)); }
  OpenTextFile(p, mode, create) { return new TextStream(p, mode, create); }
  GetParentFolderName(p) { return toVirtual(path.dirname(toReal(p))); }
  GetFolder(p) { return new FolderObject(toReal(p)); }
  GetFile(p) { return new FileObject(toReal(p)); }
  GetFileName(p) { return path.basename(toReal(p)); }
  CopyFolder(a, b, overwrite) { copyDir(toReal(a), toReal(b), overwrite); }
  CopyFile(a, b, overwrite) {
    const dst = toReal(b); fs.mkdirSync(path.dirname(dst), { recursive: true });
    if (fs.existsSync(dst) && !overwrite) throw new Error("destination exists");
    fs.copyFileSync(toReal(a), dst);
  }
  DeleteFile(p) { fs.rmSync(toReal(p), { force: true }); }
  DeleteFolder(p) { fs.rmSync(toReal(p), { recursive: true, force: true }); }
  GetDriveName() { return "X:"; }
  GetDrive() { return { DriveType: 1, FileSystem: "FAT32", AvailableSpace: 1024 * 1024 * 512 }; }
}
const elements = {};
function element(id) {
  if (!elements[id]) elements[id] = { id, innerHTML: "", innerText: "", value: "", className: "hidden", checked: false, style: { display: "none" } };
  return elements[id];
}
for (const id of ["platformFilter", "cards", "count", "diagnostics", "toolsPanel", "importReport", "systemsPanel", "find", "modeButton", "overlay", "helpTitle", "helpText"]) element(id);
const alerts = [], runs = [];
const shell = {
  CurrentDirectory: virtualRoot,
  Run(command) { runs.push(command); return 0; },
  RegRead() { throw new Error("not in test"); },
  ExpandEnvironmentStrings() { return "x86"; }
};
const context = {
  console,
  Enumerator,
  ActiveXObject: function (name) {
    if (name === "Scripting.FileSystemObject") return new FSO();
    if (name === "WScript.Shell") return shell;
    if (name === "Shell.Application") return { BrowseForFolder() { return null; } };
    if (name === "SAPI.SpVoice") return { Speak() {} };
    throw new Error("unexpected ActiveX object " + name);
  },
  document: { body: { className: "" }, getElementById: element, onkeydown: null },
  window: { event: null, resizeTo() {}, prompt() { return null; } },
  location: { pathname: "/X:/Plugcade/Plugcade.hta" },
  alert(value) { alerts.push(String(value)); },
  confirm() { return false; },
  unescape,
  encodeURI,
  setTimeout,
  clearTimeout
};
vm.createContext(context);
vm.runInContext(scripts.join("\n"), context, { filename: "Plugcade.hta" });
context.root = virtualRoot;
context.ensure(virtualRoot + "\\Config");
function write(virtual, data) {
  const file = toReal(virtual); fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, data);
}
context.loadSettings();
assert(context.firstRun, "empty portable folder should trigger first-run setup");
write(virtualRoot + "\\Config\\settings.ini", "kidmode=1\r\nplatforms=DOS,NES,PS1\r\n");
context.loadSettings();
assert(!context.firstRun, "existing 0.3 settings should be recognized as an upgrade");
assert.equal(context.cfg.autoimport, "1", "0.3 upgrade should enable safe startup import by default");
assert.equal(context.cfg.setupcomplete, "1", "0.3 users should not be forced through first-run again");
context.ensureTree();
write(virtualRoot + "\\DROP_GAMES_HERE\\_SMART_INBOX\\Mario.nes", "NES");
write(virtualRoot + "\\DROP_GAMES_HERE\\_SMART_INBOX\\mystery.bin", "AMBIGUOUS");
write(virtualRoot + "\\DROP_GAMES_HERE\\PS1\\Ridge.cue", 'FILE "Ridge.bin" BINARY\n  TRACK 01 MODE2/2352\n');
write(virtualRoot + "\\DROP_GAMES_HERE\\PS1\\Ridge.bin", "TRACK-DATA");
write(virtualRoot + "\\DROP_GAMES_HERE\\DOS\\Doom\\DOOM.EXE", "DOS-PROGRAM");
write(virtualRoot + "\\Emulators\\NES\\Mesen\\setup.exe", "bad");
write(virtualRoot + "\\Emulators\\NES\\Mesen\\mesen.exe", "good");

context.doImport(true);
assert(fs.existsSync(toReal(virtualRoot + "\\Library\\NES\\Mario\\Mario.nes")), "Smart Inbox should import unique ROM formats");
assert(fs.existsSync(toReal(virtualRoot + "\\Library\\PS1\\Ridge\\Ridge.cue")), "disc descriptor should import");
assert(fs.existsSync(toReal(virtualRoot + "\\Library\\PS1\\Ridge\\Ridge.bin")), "CUE companion track should import");
assert(!fs.existsSync(toReal(virtualRoot + "\\Library\\GENESIS\\mystery\\mystery.bin")), "ambiguous BIN must not be guessed");
assert(context.importStats.needs.some((x) => x.includes("mystery.bin")), "ambiguous file should be reported");
assert.equal(context.emulatorFor(context.platform("NES")).exe, virtualRoot + "\\Emulators\\NES\\Mesen\\mesen.exe", "nested emulator discovery should ignore setup.exe");
assert(context.games.some((g) => g.title === "Mario"), "catalogue should contain imported ROM");
assert(context.games.some((g) => g.title === "Ridge"), "catalogue should contain grouped disc game");
const doom = context.games.find((g) => g.title === "Doom");
assert(doom, "catalogue should contain imported DOS folder");
const work = context.prepareDos(doom);
assert(fs.existsSync(toReal(work + "\\DOOM.EXE")), "DOS game should receive a writable portable work copy");
assert(fs.existsSync(toReal(virtualRoot + "\\Config\\games.tsv")), "plain-text catalogue should be written");
write(virtualRoot + "\\Saves\\NES\\test-game\\battery.sav", "SAVE");
let backupNumber = 0;
context.timeKey = () => `20260717_12000${backupNumber++}`;
for (let i = 0; i < 4; i++) assert(context.backupSaves(true), "manual save backup should succeed");
const backups = fs.readdirSync(toReal(virtualRoot + "\\Backups")).filter((x) => x.startsWith("Saves_"));
assert.equal(backups.length, 3, "only the newest three Plugcade save backups should remain");
const idA = context.gameId(context.platform("NES"), virtualRoot + "\\Library\\NES\\Mario\\Mario.nes");
context.root = "Q:\\Plugcade";
const idB = context.gameId(context.platform("NES"), "Q:\\Plugcade\\Library\\NES\\Mario\\Mario.nes");
assert.equal(idA, idB, "portable game ID must survive a drive-letter change");

console.log(`Plugcade smoke tests passed: ${context.platforms.length} adapters, ${context.games.length} games, ${html.length} byte HTA.`);
fs.rmSync(temp, { recursive: true, force: true });
