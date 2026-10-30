import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {execFileSync} from 'node:child_process';

try {
const manifest=JSON.parse(fs.readFileSync('backup/manifest.json','utf8'));
const digest=async p=>{const h=crypto.createHash('sha256');for await(const b of fs.createReadStream(p))h.update(b);return h.digest('hex')};
const check=(ok,msg)=>{if(!ok)throw new Error(msg)};
check(await digest('backup/file-manifest.json')===manifest.file_manifest_sha256,'File manifest checksum mismatch');
fs.mkdirSync('dist',{recursive:true});
const archive=path.join('dist',manifest.archive.name);
const fd=fs.openSync(archive,'w');
const h=crypto.createHash('sha256');
let total=0;
try {
 for(const part of manifest.parts) {
  check(/^project\.tar\.gz\.part-[a-z]{4}$/.test(part.name),'Unsafe part name');
  const b=fs.readFileSync(path.join('backup/parts',part.name));
  check(b.length===part.bytes,'Wrong part size: '+part.name);
  check(crypto.createHash('sha256').update(b).digest('hex')===part.sha256,'Wrong part hash: '+part.name);
  fs.writeSync(fd,b);h.update(b);total+=b.length;
  console.log('Verified and assembled '+part.name);
 }
} finally {fs.closeSync(fd)}
check(total===manifest.archive.bytes,'Archive length mismatch');
check(h.digest('hex')===manifest.archive.sha256,'Archive SHA-256 mismatch');
fs.mkdirSync('restore',{recursive:true});
execFileSync('tar',['--warning=no-unknown-keyword','-xpzf',archive,'-C','restore'],{stdio:'inherit'});
const root=path.resolve('restore',manifest.root_directory);
const files=JSON.parse(fs.readFileSync('backup/file-manifest.json','utf8'));
let count=0,bytes=0;
for(const entry of files.entries) {
 check(!path.isAbsolute(entry.path)&&!entry.path.split('/').includes('..'),'Unsafe original path');
 const file=path.join(root,entry.path),stat=fs.lstatSync(file);
 check((stat.mode&0o7777)===entry.mode,'Mode mismatch: '+entry.path+' expected='+entry.mode.toString(8)+' actual='+(stat.mode&0o7777).toString(8));
 if(entry.type==='directory')check(stat.isDirectory(),'Directory missing: '+entry.path);
 else if(entry.type==='symlink')check(stat.isSymbolicLink()&&fs.readlinkSync(file)===entry.target,'Symlink mismatch: '+entry.path);
 else {
  check(stat.isFile()&&stat.size===entry.size,'File size/type mismatch: '+entry.path);
  check(await digest(file)===entry.sha256,'File content mismatch: '+entry.path);
  count++;bytes+=stat.size;
 }
}
check(count===files.files&&bytes===files.bytes,'Original file count or total byte count mismatch');
const head=execFileSync('git',['-C',root,'rev-parse','HEAD'],{encoding:'utf8'}).trim();
check(head===manifest.source_commit,'Original Git HEAD mismatch');
console.log(execFileSync('git',['-C',root,'fsck','--full'],{encoding:'utf8',stdio:'pipe'}));
fs.copyFileSync(path.join(root,'output/quantum-computing.mp4'),'dist/quantum-computing.mp4');
fs.copyFileSync(path.join(root,'output/quantum-computing-source.zip'),'dist/quantum-computing-source.zip');
fs.copyFileSync('backup/file-manifest.json','dist/file-manifest.json');
fs.copyFileSync('backup/manifest.json','dist/backup-manifest.json');
fs.copyFileSync('backup/RESTORE.md','dist/RESTORE.md');
const verification={verified_at:new Date().toISOString(),passed:true,original_files:count,original_bytes:bytes,source_commit:head,archive:manifest.archive,parts_verified:manifest.parts.length,git_fsck:'passed'};
fs.writeFileSync('dist/verification.json',JSON.stringify(verification,null,2)+'\n');
const artifacts=[];
for(const name of fs.readdirSync('dist').sort())artifacts.push({name,bytes:fs.statSync('dist/'+name).size,sha256:await digest('dist/'+name)});
fs.writeFileSync('dist/SHA256SUMS',artifacts.map(a=>a.sha256+'  '+a.name).join('\n')+'\n');
fs.writeFileSync('release-artifacts.json',JSON.stringify(artifacts,null,2));
console.log(JSON.stringify(verification,null,2));


} catch (error) {
 const message=(String(error.stack||error)+'\n'+String(error.stderr||'')).replace(/\r/g,'').replace(/\n/g,'%0A');
 console.error('::error title=Full backup validation failed::'+message);
 if(process.env.GITHUB_STEP_SUMMARY)fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY,'\nBackup validation failed:\n\n'+String(error.stack||error)+'\n'+String(error.stderr||'')+'\n');
 process.exit(1);
}
