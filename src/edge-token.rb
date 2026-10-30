#!/usr/bin/ruby
# Ruby adaptation of edge-tts src/edge_tts/drm.py (rany et al.).
# This file is licensed under LGPL-3.0; upstream source and license are
# retained in content/vendor/edge-tts/. No Python interpreter is used.
require 'json'
SOURCE = File.read(File.expand_path('../content/vendor/edge-tts/drm.py.txt', __dir__))
def constants(name)
  block=SOURCE.match(/#{Regexp.escape(name)} = \((.*?)^\)/m)[1]
  block.scan(/0x[0-9A-Fa-f]+/).map{|s|s.to_i(16)}
end
M=0xffffffff
INITIAL=constants('_SHA256_INITIAL')
STATE=constants('_SHA256_STATE')
SCHEDULE=constants('_SHA256_SCHEDULE')
K=constants('_SHA256_ROUND_CONSTANTS')
COEFF=constants('_CS64_COEFFICIENTS').each_slice(2).to_a
def rotr(x,n);((x>>n)|(x<<(32-n)))&M;end
def rol16(x);((x<<16)|(x>>16))&M;end
def sigma0(x);rotr(x,7)^rotr(x,18)^(x>>3);end
def sigma1(x);rotr(x,17)^rotr(x,19)^(x>>10);end
def expand(w,first=16)
 (first...64).each{|i|w << ((sigma1(w[i-2])+w[i-7]+sigma0(w[i-15])+w[i-16])&M)}
end
def rounds(state,w,first=0)
 a,b,c,d,e,f,g,h=state
 (first...64).each do |i|
  ki=(first==14 && i==14) ? 0xC9DC06A7 : K[i]
  t1=(h+(rotr(e,6)^rotr(e,11)^rotr(e,25))+(g^(e&(f^g)))+ki+w[i])&M
  t2=((rotr(a,2)^rotr(a,13)^rotr(a,22))+((a&b)|(c&(a|b))))&M
  a,b,c,d,e,f,g,h=(t1+t2)&M,a,b,c,(d+t1)&M,e,f,g
 end
 [a,b,c,d,e,f,g,h]
end
def sha_init(data)
 w=Array.new(14,0)+[("\x00".b+data[0,3]).unpack1('N'),data[3,4].unpack1('N')]
 (16...30).each do |i|
  v=SCHEDULE[i-16]
  v += i==16 ? (sigma1(w[i-2])^0x000B92C0) : sigma1(w[i-2]) if i-2>=14
  v += w[i-7] if i-7>=14
  v += i==29 ? (sigma0(w[i-15])^0x059C0B80) : sigma0(w[i-15]) if i-15>=14
  w << (v&M)
 end
 w << ((sigma1(w[28])+w[23]+sigma0(w[15])+w[14]+0xC9DC06A7-K[14])&M)
 expand(w,31)
 INITIAL.zip(rounds(STATE,w,14)).map{|x,y|(x+y)&M}
end
def digest(data)
 length=57+data.bytesize
 padded=data[7..-1]+"\x80".b+"\x00".b*((55-length)%64)+[length*8].pack('Q>')
 state=sha_init(data[0,7])
 padded.bytes.each_slice(64) do |block|
  w=block.pack('C*').unpack('N16');expand(w)
  state=state.zip(rounds(state,w)).map{|x,y|(x+y)&M}
 end
 state.pack('N8')
end
def cs64(data,hash)
 ka,kb=hash.unpack('V2');ka|=1;kb|=1
 factors=[(ka*0x82893933)&M,(kb*0x82893933)&M]
 terms=COEFF.each_with_index.map{|(co,_),i|(co*factors[i%2])&M}
 offsets=COEFF.map{|_,off|off}
 padded="\x00".b+data
 padded += "\x00".b*((-padded.bytesize)%4)
 words=padded.unpack('V*');words<<0 if words.length.odd?
 words.each_with_index do |word,i|
  term=word*(i.even? ? ka:kb)
  off=rol16(word)*(i.even? ? 0xEF0569FB:0xC31713DB)
  if i==0;term+=0xF2F90B1A*factors[0];off+=0x0B1A0000;end
  terms<< (term&M);offsets<< (off&M)
 end
 swap_acc=swap_last=state=acc=0
 (0...terms.length).step(2) do |i|
  x,y=terms[i,2]
  t=rol16((offsets[i]+x)&M);q=(t*0x76F50F34)&M
  swap_acc += (rol16(q)*0xC3EFEA97+q)&M
  t=rol16((offsets[i+1]+y)&M);q=(t*0x1881CE3C)&M
  swap_last=(rol16(q)*0x35BD1EC9+q)&M
  swap_acc=(swap_acc+swap_last)&M
  state=(state*ka+x)&M
  [0xCF98B111,0x87085B9F,0x12CEB96D,0x257E1D83].each{|v|state=(rol16(state)*v)&M}
  acc+=state
  t=(state*kb+y)&M
  [0xA27416F5,0xD38396FF,0x7C932B89,0xBFA49F69].each{|v|t=(rol16(t)*v)&M}
  state=t;acc=(acc+state)&M
 end
 [swap_last^state,swap_acc^acc].pack('V2')
end
now=Time.now.to_f+11644473600
ticks=((now-now%300)*10000000).round
salt="#{ticks}6A5AA1D4EAFF4E9FB37E23D68491D6F4".b
hash=digest(salt)
puts "#{cs64(salt,hash).unpack1('H*').upcase}-#{hash.unpack1('H*').upcase}"

