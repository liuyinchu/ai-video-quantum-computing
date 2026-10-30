# 资料来源与事实核验

本片面向普通大众，图示为概念示意；内容没有宣称量子计算能解决所有困难问题，也没有把厂商路线图当作已实现能力。查阅日期：2026-10-30。

| 主题 | 主要来源 | 用于核验的内容 |
| --- | --- | --- |
| 比特、量子比特、叠加与量子电路 | [IBM Quantum — Quantum computing fundamentals](https://quantum.cloud.ibm.com/learning/en/courses/quantum-business-foundations/quantum-computing-fundamentals) | 信息编码、量子态、量子门和经典计算的协作 |
| 相位、干涉与两个 H 门实验 | [IBM Quantum — Superposition with Qiskit](https://quantum.cloud.ibm.com/learning/en/modules/quantum-mechanics/superposition-with-qiskit) | 相同测量概率不代表相同量子态；理想 H²=I |
| Grover 搜索 | [IBM Quantum — Grover's algorithm](https://quantum.cloud.ibm.com/learning/en/modules/computer-science/grovers) | 无结构搜索在查询模型中获得平方级加速；不等于实际运行时间的固定倍率 |
| Shor 分解 | [IBM Quantum — Shor's algorithm](https://quantum.cloud.ibm.com/docs/en/tutorials/shors-algorithm) | 周期/阶寻找与整数分解；小数演示和实用密码规模存在巨大差距 |
| 硬件与计算基础 | [NIST — Quantum Computing Explained](https://www.nist.gov/quantum-information-science/quantum-computing-explained) | 超导、离子阱、中性原子、光子等平台及噪声挑战 |
| 后量子密码 | [NIST — 2024 首批三项标准](https://www.nist.gov/news-events/news/2024/08/nist-releases-first-3-finalized-post-quantum-encryption-standards) | ML-KEM、ML-DSA、SLH-DSA；2024 年的历史事实 |
| 后量子密码的含义 | [NIST — What Is Post-Quantum Cryptography?](https://www.nist.gov/cybersecurity-and-privacy/what-post-quantum-cryptography) | 在经典计算机上运行的抗量子密码算法 |
| 量子纠错 | [Google Quantum AI — Willow](https://blog.google/innovation-and-ai/technology/research/google-willow-quantum-chip/) | 低于阈值后的逻辑错误率改善；逻辑与物理比特的区别 |
| 潜在价值与局限 | [NIST — Assessing the Benefits and Risks of Quantum Computers](https://www.nist.gov/publications/assessing-benefits-and-risks-quantum-computers) | 潜在经济用途、容错算法与密码风险；不确定的工程时间表 |
| 纠缠不允许超光速通信 | [NIST — Quantum Computing and Communication](https://tsapps.nist.gov/publication/get_pdf.cfm?pub_id=51022) | 随机的本地测量结果不能被控制来发消息 |

## 关键表达约束

- “2ⁿ”指一般 n 量子比特纯态的计算基振幅数量，不能理解为一次读出 2ⁿ 个答案。
- 水波、指针、状态球均是帮助理解数学关系的图示，并非粒子实际运行轨道。
- 贝尔态在指定共同基底中给出相关结果；单一基底下的相关性本身不能证明纠缠。
- H→H 回到 0 是理想电路的预测，真实硬件包含误差。
- Grover 比较的是理想黑盒查询复杂度；数据装载、预言机实现和容错开销需另外计算。
- Shor 对比“目前已知最好的经典分解算法”，没有声称已证明经典分解必须指数困难。
- 化学、材料、优化和机器学习用途按研究潜力陈述，没有承诺具体商业效果。
- 纠错是联合编码与错误综合征测量，不是复制未知量子态。
- “量子优势”必须明确任务、经典基线和总资源成本。

## 素材来源

- 画面：原创程序化矢量、三维投影与粒子动画，无外部照片或素材视频。
- 音乐：原创合成电子氛围音轨，程序生成。
- 配音：微软 Edge Read Aloud 的 zh-CN-YunxiNeural（云希）。原曼波社区接口日额度耗尽，最终全片统一使用用户同意的云希备选音色。客户端使用与 edge-tts 相同的公开协议；Ruby token 适配代码依据 LGPL-3.0 的 edge-tts 源码改编，来源与许可证保留在 content/vendor/edge-tts/。
- 字体：远端 macOS 自带 PingFang SC 与 Menlo；最终视频为栅格化画面，不分发字体文件。

