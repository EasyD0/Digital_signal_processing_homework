clear;
clc;close all;
theta=0.4;

A=load("快走.txt");
len_A=length(A);
A_x=A(:,1)/4096;   A_y=A(:,2)/4096;  A_z=A(:,3)/4096;

Time=length(A_x)/100;

X_Abscissa=linspace(0,Time,length(A_x)); %绘制 时域图的横坐标
X_Abscissa_f=linspace(0,2*pi,length(A_x));

Acc=sqrt(A_x.^2+A_y.^2+A_z.^2)-1;

S=delete_zero(Acc,80,theta);      %若加速度序列中, 有超过连续80(0.8秒)个点小于0.4个重力加速度,则删除
Time_D=length(S{1})/100;        %删除掉无效长度后对应的时间长度
X_Abscissa_D=linspace(0,Time_D,length(S{1}));     %绘制删除掉无效长度后时域图的横坐标
X_Abscissa_f_D=linspace(0,2*pi,length(S{1}));     %截断后频域图横坐标

%{
figure;  %绘制三周加速度计的原始数据图
    plot(X_Abscissa,A_x,  X_Abscissa,A_y,  X_Abscissa,A_z);
    axis([0,Time,min([A_x;A_y;A_z])-1,max([A_x;A_y;A_z])+1]);
    title("");
    xlabel("time(s)");
    ylabel("加速度\times9.8 m/s^2");
%}

figure;  %绘制总加速度
    plot(X_Abscissa,Acc);
    %axis([0,Time,0,max([A_x;A_y;A_z])+1]);
    xlim([0,Time]);
    title("总加速度大小");
    xlabel("time(s)");
    ylabel("加速度\times9.8m/s^2")

figure %绘制删除无效值后时域图像
    plot(X_Abscissa,S{2});
    xlim([0,Time]);
    title("删除无效值后的加速度值");
    xlabel("time(s)");

figure %绘制删除无效值后时域图像
    plot(X_Abscissa_D,S{1});
    xlim([0,Time_D]);
    title("删除无效值后的加速度值");
    xlabel("time(s)");

%对删除无效值的时域做短时傅里叶变换
%希望分辨率达到0.25Hz,那么每个窗的长度为4s,则为400个点
%采用hann窗,但是若在频域进行处理,处理之后重建信号时若不加窗可能会有问题,比如信号突变,因此也需要加窗
%因此考虑在合并前也加窗,两次加窗都使用正弦窗,若两个短时傅里叶变换之间有200点(一半)交叠,那么重建后两次加窗叠加为1;
%参考https://www.zhihu.com/question/280648561#:~:text=%E4%BA%86%E8%AF%A5%E5%9B%9E%E7%AD%94-,%E6%88%91%E5%B8%B8%E7%94%A8%E7%9A%84%E5%81%9A%E6%B3%95%E6%98%AF%EF%BC%9A,-%E5%B8%A7%E9%95%BF%E5%8F%96

%[Z,F,T]=specgram([Acc;zeros(400,1)],399,100,hanning(400),399); %specgram似乎是过时的,现在一般用spectrogram或stft做短时傅里叶
%[Z,F,T]=spectrogram(Acc,sin(linspace(0,pi,400)),200,400,100); %400点dft,窗函数为正弦窗,每次400点fft,两组交叠399点,原信号采样频率为100Hz
%spectrogram虽然每组400点,但是由于对称性,只有201个值是有效的,spectrogram函数默认只返回这201个值.这样不利于反变换
%参考 https://ww2.mathworks.cn/help/signal/ref/istft.html 做反变换
[Z,F,T] = stft(S{1},100,'Window',hamming(500,'periodic'),'OverlapLength',499);

figure;
surf(T,F,abs(Z)); %绘制的是曲面图
%waterfall(F,T,abs(Z')); %绘制瀑布图
%view(-80,30); %为3D图像设置观察角度 
shading interp;
colormap(cool);
xlabel('Time');
ylabel('Frequency');
zlabel('spectrogram');


%去除掉1-3Hz以外的值
Z(250-5:250+5,:)=0;
Z(250+16:end,:)=0;
Z(1:250-16,:)=0;
%{
Z(200-4:200+4,:)=0;
Z(200+13:end,:)=0;
Z(1:200-13,:)=0;    
%}

%同样通过比较法来获取
temp=sort(abs(Z),1,'descend');
Z=Z.*(abs(Z)>=temp(5,:));

figure;
surf(T,F,abs(Z)); %绘制的是曲面图
%waterfall(F,T,abs(Z')); %绘制瀑布图
%view(-80,30); %为3D图像设置观察角度 
shading interp;
colormap(cool);
xlabel('Time');
ylabel('Frequency');
zlabel('spectrogram');

%反变换
[ix,it]=istft(Z,100,'Window',hamming(500,'periodic'),'OverlapLength',499);
figure;
plot(it,ix);
ix=connect_signal(ix,S{3},S{4},len_A);
plot(ix);
[peaks,locs]=findpeaks(ix,X_Abscissa);
figure
    stairs([0,locs,locs(end)+1],[0,1:length(locs),length(locs)]); 
    %这里末尾加1个同样的值是为了拖长最后一个阶梯,且加了一个开始点(0,0)
    xlim([0,Time+1]);
    title("计步");
    xlabel("时间(s)");
    ylabel("步数")



