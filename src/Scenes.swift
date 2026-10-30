import Foundation
import CoreGraphics
func graphic(_ c:CGContext,_ scene:Scene,_ t:Double,_ progress:Double,_ phase:Int) {
 switch scene.mode {
 case "hero","finale":
  orbit(c,1375,530,245,t,cyan,true)
  for i in 0..<7 {let x=1080+Double(i)*110,y=790+sin(t*0.3+Double(i))*16;disc(c,x,y,3,alpha(cyan,0.7),true)}
  text(c,"Q U A N T U M",116,345,31,cyan)
  text(c,scene.title,110,410,scene.mode=="hero" ? 142:96,white,false,false,970)
  text(c,scene.subtitle,118,595,37,muted,false,false,1050)
  line(c,118,700,468,700,cyan,3,true)
  text(c,scene.mode=="hero" ? "叠加  /  干涉  /  纠缠":"把好奇心，变成理解世界的能力",118,735,28,white)
 case "bits":
  for r in 0..<3 {for col in 0..<8 {
   let x=150+Double(col)*208,y=365+Double(r)*145
   let active=(col+r+Int(t*1.3))%5==0
   box(c,x,y,160,108,active ? cyan:muted,active ? 0.18:0.03)
   let bit=(col*7+r*3+Int(t/2))%2
   text(c,"\(bit)",x+80,y+15,64,active ? cyan:white,true,true)
  }}
  text(c,"电路中的可控状态  →  逻辑门  →  程序",960,830,31,cyan,true)
 case "sphere":
  orbit(c,620,560,205,t,cyan,true)
  let q=proj(P3(x:0.68*cos(t*0.3),y:-0.5,z:0.68*sin(t*0.3)),t,620,560,205)
  arrow(c,620,560,q.x,q.y,orange);disc(c,q.x,q.y,9,orange,true)
  text(c,"|0〉",620,306,35,white,true);text(c,"|1〉",620,803,35,white,true)
  text(c,"|ψ〉 = α|0〉 + β|1〉",1120,420,49,white,false,false,650)
  text(c,"概率：|α|² + |β|² = 1",1120,515,32,cyan,false,false,650)
  text(c,"振幅大小",1120,640,39,white);text(c,"决定概率",1440,645,30,muted)
  text(c,"相对相位",1120,716,39,violet);text(c,"决定干涉",1440,722,30,muted)
 case "phase":
  for i in 0..<2 {
   let cx=480+Double(i)*960
   ring(c,cx,560,148,alpha(cyan,0.24));ring(c,cx,560,160,alpha(violet,0.18))
   let a=t*0.45, b=a+(i==0 ? 0.0:Double.pi)
   arrow(c,cx,560,cx+125*cos(a),560+125*sin(a),cyan)
   arrow(c,cx,560,cx+(i==0 ? 92:125)*cos(b),560+(i==0 ? 92:125)*sin(b),violet)
   text(c,i==0 ? "同向 / +":"反向 / −",cx,750,38,white,true)
   text(c,"直接测量：0 与 1 各 50%",cx,820,28,muted,true)
  }
  text(c,"相位",960,515,44,orange,true);text(c,"改变后续结果",960,589,29,white,true)
 case "measure":
  orbit(c,430,570,165,t,cyan,false)
  arrow(c,690,570,880,570,cyan);gate(c,980,570,"M",orange)
  arrow(c,1070,570,1200,570,orange)
  let value=Int(t*2.3)%3==0 ? "1":"0"
  text(c,value,1430,410,180,white,true,true)
  text(c,"单次结果",1430,638,32,muted,true)
  let vals=(0..<18).map{(($0*13+7)%7)%2}
  for (i,v) in vals.enumerated(){text(c,"\(v)",210+Double(i)*87,800,36,i==Int(t*3)%18 ? orange:muted,true,true)}
  text(c,"重新准备同一量子态，再统计许多次",960,735,30,cyan,true)
 case "exponential":
  let labels=["1 qubit","2 qubits","3 qubits","n qubits"], nums=["2","4","8","2ⁿ"]
  for i in 0..<4 {
   let x=140+Double(i)*445
   text(c,labels[i],x+155,370,26,muted,true,true)
   text(c,nums[i],x+155,430,96,i==3 ? orange:cyan,true,true)
   for j in 0..<(i==3 ? 32 : (1<<(i+1))) {
    let col=j%8,row=j/8
    disc(c,x+30+Double(col)*36,630+Double(row)*37,6,alpha(i==3 ? orange:cyan,0.45+0.4*sin(t+Double(j))*sin(t+Double(j))),true)
   }
  }
  box(c,440,810,1040,70,violet,0.08);text(c,"一次测量 → 一串 n 位的经典结果",960,823,33,white,true)
 case "waves":
  let ph=t*1.8
  text(c,"增强",160,370,36,cyan);text(c,"抵消",160,640,36,violet)
  wave(c,310,435,530,42,ph,cyan)
  wave(c,310,435,530,42,ph+0.12,violet)
  arrow(c,880,435,1020,435,muted)
  wave(c,1080,435,660,84,ph,mint)
  wave(c,310,700,530,42,ph,cyan)
  wave(c,310,700,530,42,ph+Double.pi,violet)
  arrow(c,880,700,1020,700,muted)
  wave(c,1080,700,660,0,ph,orange,3,0)
  text(c,"相位对齐",570,530,26,muted,true);text(c,"相位相反",570,795,26,muted,true)
  text(c,"振幅相加",1400,530,26,mint,true);text(c,"振幅归零",1400,795,26,orange,true)
 case "hadamard","try":
  let yy=500.0
  line(c,245,yy,1660,yy,alpha(cyan,0.5),3)
  text(c,"|0〉",175,yy-34,52,white,true)
  gate(c,540,yy,"H",cyan);gate(c,1080,yy,"H",violet)
  text(c,"测量",1630,yy-105,30,muted,true)
  text(c,"0",1630,yy-50,90,mint,true,true)
  let pulse=245+(t.truncatingRemainder(dividingBy:6)/6)*1350
  disc(c,pulse,yy,8,white,true)
  text(c,"50% / 50%",775,635,42,cyan,true)
  text(c,"100% / 0%",1430,635,42,mint,true)
  text(c,"先不测量",775,715,30,muted,true)
  text(c,"理想结果",1430,715,30,muted,true)
  text(c,scene.mode=="try" ? "下一步：H + CNOT → 纠缠比特":"两次相同的操作，让振幅重新汇合",960,818,32,orange,true)
 case "circuit":
  for row in 0..<3 {
   let yy=440+Double(row)*155
   text(c,"q\(row)",170,yy-25,37,muted,true,true)
   line(c,240,yy,1700,yy,alpha(cyan,0.3),2)
   let px=240+(t.truncatingRemainder(dividingBy:8)/8)*1430
   disc(c,px,yy,5,cyan,true)
  }
  gate(c,420,440,"H");gate(c,640,595,"Rz",violet)
  line(c,880,440,880,750,cyan,3,true);disc(c,880,440,12,cyan,true);ring(c,880,750,30,cyan,3);line(c,850,750,910,750,cyan,3);line(c,880,720,880,780,cyan,3)
  gate(c,1140,440,"Ry",violet);gate(c,1140,595,"H")
  for y in [440.0,595,750] {gate(c,1540,y,"M",orange)}
 case "entangle","correlation":
  orbit(c,475,565,145,t,cyan,false);orbit(c,1445,565,145,-t,violet,false)
  for j in 0..<12 {
   var points=[CGPoint]()
   for i in 0...120 {let u=Double(i)/120;let v=sin(u*Double.pi)*sin(u*3*Double.pi+t+Double(j)*0.22);points.append(CGPoint(x:620+u*680,y:565+v*Double(28+j*5)))}
   path(c,points,alpha(j%2==0 ? cyan:violet,0.10),1.8)
  }
  if scene.mode=="entangle" {
   text(c,"(|00〉 + |11〉) / √2",960,345,57,white,true)
   text(c,"A",475,770,37,cyan,true);text(c,"B",1445,770,37,violet,true)
   let n=Int(t*0.9)%2
   text(c,"\(n)",475,520,70,white,true,true);text(c,"\(n)",1445,520,70,white,true,true)
   text(c,"一个整体状态",960,785,32,orange,true)
  } else {
   text(c,"局部随机",475,775,35,cyan,true);text(c,"局部随机",1445,775,35,violet,true)
   text(c,"无法控制结果",960,360,38,orange,true)
   text(c,"比较统计需要经典通信",960,805,32,white,true)
   line(c,850,565,1070,565,orange,3);line(c,920,535,980,595,orange,4);line(c,980,535,920,595,orange,4)
  }
 case "grover":
  for r in 0..<12 {for col in 0..<27 {
   let i=r*27+col,x=155+Double(col)*29,y=380+Double(r)*29
   let target=i==192,selected=i==Int(t*40)%324
   disc(c,x,y,target ? 8:3,target ? mint:(selected ? white:alpha(cyan,0.25)),target)
  }}
  text(c,"未排序的候选集合",540,810,29,muted,true)
  text(c,"1,000,000",1360,395,75,white,true,true)
  text(c,"经典查询数量级",1360,492,28,muted,true)
  arrow(c,1360,550,1360,600,violet)
  text(c,"1,000",1360,630,91,mint,true,true)
  text(c,"量子查询数量级",1360,748,28,mint,true)

 case "shor":
  text(c,"15 = 3 × 5",480,425,78,white,true,true)
  text(c,"小数演示 ≠ 破解现实密码",480,555,29,muted,true)
  wave(c,920,480,780,90,t*0.5,cyan,4)
  for i in 0..<5 {line(c,920+Double(i)*195,350,920+Double(i)*195,650,alpha(violet,0.28),1)}
  text(c,"重复结构 → 周期信息",1310,690,34,cyan,true)
  let a=["构造函数","量子找周期","经典求因子"]
  for i in 0..<3 {let x=310+Double(i)*590;box(c,x-180,785,360,70,i==1 ? violet:cyan);text(c,a[i],x,798,31,white,true)}
 case "crypto":
  for i in 0..<3 {
   let x=150+Double(i)*580
   box(c,x,390,470,360,i==1 ? violet:cyan,0.06)
   ring(c,x+235,490,55,alpha(cyan,0.5),3)
   line(c,x+207,490,x+229,513,mint,5,true);line(c,x+229,513,x+273,467,mint,5,true)
   text(c,["ML-KEM","ML-DSA","SLH-DSA"][i],x+235,595,42,white,true,true)
   text(c,["密钥建立","数字签名","数字签名"][i],x+235,671,30,muted,true)
  }
  text(c,"2024  /  首批三项标准",960,816,34,mint,true)
 case "molecule":
  let atoms:[P3]=[P3(x:0,y:0,z:0),P3(x:0.9,y:0.35,z:0.1),P3(x:-0.7,y:0.5,z:0.4),P3(x:-0.1,y:-0.8,z:-0.4),P3(x:0.4,y:0.4,z:-0.8),P3(x:1.3,y:0.9,z:0.3),P3(x:-1.1,y:0.85,z:0.8)]
  let ps=atoms.map{proj($0,t,680,580,195)}
  for i in 1..<5 {line(c,ps[0].x,ps[0].y,ps[i].x,ps[i].y,alpha(cyan,0.5),9,true)}
  for (a,b) in [(1,5),(2,6)] {line(c,ps[a].x,ps[a].y,ps[b].x,ps[b].y,alpha(violet,0.5),7,true)}
  for i in ps.indices.sorted(by:{ps[$0].z<ps[$1].z}) {let q=ps[i];disc(c,q.x,q.y,i==0 ? 40:26,i%3==0 ? violet:cyan,true);disc(c,q.x-8,q.y-10,6,alpha(white,0.8))}
  text(c,"电子结构",1310,430,48,white,true);text(c,"反应路径",1310,550,48,cyan,true);text(c,"材料性质",1310,670,48,violet,true)
  text(c,"示意分子，非特定化学结构",670,835,24,muted,true)
 case "limits":
  let labels=["问题结构","数据装载","精度要求","经典基线"]
  for i in 0..<4 {
   let x=160+Double(i)*435
   ring(c,x+150,490,85,alpha(i%2==0 ? cyan:violet,0.5),3)
   text(c,"0\(i+1)",x+150,445,63,i%2==0 ? cyan:violet,true,true)
   text(c,labels[i],x+150,660,40,white,true)
  }
  text(c,"优势，要逐个问题验证",960,800,42,orange,true)
 case "hardware":
  let labels=["超导电路","离子阱","中性原子","光量子"]
  for i in 0..<4 {
   let x=150+Double(i)*440,cx=x+150
   box(c,x,360,330,420,i%2==0 ? cyan:violet,0.04)
   if i==0 {
    for j in 0..<5 {let y=420+Double(j)*43;line(c,cx-70+Double(j)*10,y,cx+70-Double(j)*10,y,orange,9,true);line(c,cx-60,y,cx-60,y+43,alpha(orange,0.4),2);line(c,cx+60,y,cx+60,y+43,alpha(orange,0.4),2)}
   } else if i==1 {
    for j in 0..<4 {disc(c,x+65+Double(j)*65,525,10,cyan,true)}
    line(c,x+40,480,x+290,480,violet,3);line(c,x+40,570,x+290,570,violet,3)
   } else if i==2 {
    for a in 0..<4 {for b in 0..<4 {disc(c,x+75+Double(a)*60,435+Double(b)*57,6,mint,true)}}
   } else {
    for j in 0..<3 {wave(c,x+35,460+Double(j)*65,260,20,t*2+Double(j),j%2==0 ? violet:cyan,2)}
   }
   text(c,labels[i],cx+15,687,38,white,true)
  }
  text(c,"没有一种外形，能代表所有量子计算机",960,835,29,muted,true)
 case "noise":
  orbit(c,520,565,180,t,cyan,true)
  for j in 0..<14 {
   let a=Double(j)*0.45+t*0.1,r=255+sin(t+Double(j))*15
   arrow(c,520+cos(a)*r,565+sin(a)*r,520+cos(a)*(r-25),565+sin(a)*(r-25),alpha(orange,0.5))
  }
  text(c,"相干性",1320,370,36,white,true)
  var pts=[CGPoint]()
  for i in 0...240 {let u=Double(i)/240;pts.append(CGPoint(x:950+u*750,y:740-300*exp(-u*3.4)+sin(u*40+t)*u*10))}
  path(c,pts,orange,4,true);line(c,950,745,1730,745,alpha(white,0.2))
  text(c,"时间 →",1670,780,28,muted,true)
  text(c,"环境扰动，让相位关系逐渐丢失",1320,835,29,muted,true)
 case "qec":
  for r in 0..<5 {for col in 0..<5 {
   let x=230+Double(col)*102,y=380+Double(r)*102
   if r<4 {line(c,x,y,x,y+102,alpha(cyan,0.25),2)}
   if col<4 {line(c,x,y,x+102,y,alpha(cyan,0.25),2)}
   let error=(r==2 && col==2),checking=(r+col)%2==0
   disc(c,x,y,checking ? 13:20,error ? orange:(checking ? violet:cyan),true)
   if error {ring(c,x,y,32+sin(t*3)*6,alpha(orange,0.6),2)}
  }}
  arrow(c,840,580,1020,580,cyan)
  orbit(c,1360,555,150,t,mint,false)
  text(c,"逻辑量子比特",1360,780,40,mint,true)
  text(c,"物理比特 + 辅助检查",440,847,28,muted,true)
  text(c,"编码与纠错",930,690,27,white,true)
 case "roadmap":
  let qs=["完成了什么任务？","和哪种经典算法比？","全部资源算进去了吗？"]
  for i in 0..<3 {
   let y=365+Double(i)*155
   text(c,"0\(i+1)",195,y,58,i==1 ? violet:cyan,true,true)
   line(c,285,y+35,400,y+35,alpha(cyan,0.4),2)
   text(c,qs[i],470,y+4,48,white,false,false,1300)
  }
  text(c,"可复现  /  可扩展  /  有用的逻辑运算",960,850,30,orange,true)
 case "recap":
  let labels=["叠加","干涉","纠缠"],eng=["STATE SPACE","AMPLITUDES","CORRELATIONS"]
  for i in 0..<3 {
   let cx=360+Double(i)*600
   if i==0 {orbit(c,cx,520,110,t,cyan,false)}
   else if i==1 {wave(c,cx-190,520,380,50,t,cyan,2);wave(c,cx-190,520,380,50,t+sin(t*0.4),violet,2)}
   else {orbit(c,cx-70,520,65,t,cyan,false);orbit(c,cx+70,520,65,-t,violet,false);line(c,cx-40,520,cx+40,520,violet,3,true)}
   text(c,labels[i],cx,715,65,white,true)
   text(c,eng[i],cx,817,22,i==1 ? violet:cyan,true,true)
  }
 case "credits":
  let entries=[("01","IBM Quantum Learning","基本概念、量子电路、Grover 与 Shor 算法"),("02","NIST","量子计算科普与后量子密码标准"),("03","Google Quantum AI","量子纠错与逻辑量子比特研究")]
  for (i,e) in entries.enumerated() {
   let y=365+Double(i)*150
   text(c,e.0,170,y+7,42,cyan,true,true)
   text(c,e.1,290,y,44,white)
   text(c,e.2,290,y+65,28,muted)
  }
  text(c,"完整文稿、来源与工程文件随片提供",960,862,31,mint,true)
 default: orbit(c,960,570,220,t)
 }
}

