# GAMES202 homework2

- 以下為提交作業内容, 沒有做bonus 部分:
[5 分] 提交的格式正确，包含所有必须的文件。代码可以编译和运行。
- Homework breaks into PRT and Runtime Folder with just source code and other libaries deleted.

• [10 分] 预计算环境光照：
- Prt source contains the source code to generate different Shadow and UnShadowed light.txt and transport.txt.

• [5 分] 预计算 Diffuse Unshadowed LT：
- Runtime Source can render unshadowed SH mary.

• [15 分] 预计算 Diffuse Shadowed LT：
- Runtime Source can render shadowed SH mary.

• [5 分] 预计算数据使用：
- Runtime Source can render different Environment Box with different SH.



1. 利用Nori 生成預計算代碼

 - 在　prt.cpp　PRT 預計算部分Source 主要加入了　unshadowed 和　shadowed 算法生成不同場景的　light.txt 和　transport.txt

2. 在runtime 項目裏
　
 - 在　engine.js 裏取消注釋的代碼，　讓代碼順利可以都進light 和　transport 數據到　precomputeLT 和　precomputeL, 并且加載了mary的模型(loadObj.js)
 - 在　loadObj.js 裏創建了　MaterialPRT 的case 
 - 創建了　Material PRT 以及對應的　vertex 和　fragment shader
 - 在更新　camera matrix 的地方，　實時更新了 precomputeRGB 的uniform 變量
 - 在vertex shader 裏，　讀取了SH 0,1,2 等級，　并且做了dot product 計算SH Color
 - 在Fragment shader 把　顔色做了一個　/3.14 以及　gamma 矯正，　確實在很亮的場景好看些，　因爲沒有tonemapping吧
　
