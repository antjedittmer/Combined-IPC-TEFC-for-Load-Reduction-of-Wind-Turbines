clear; close all;

t = 0:0.01:10;
lenT = length(t);
omega = 2*pi;

M_flap(1,:) = sin(omega*t); 
M_flap(2,:) = sin(omega*t - 2/3*pi); 
M_flap(3,:) = sin(omega*t - 4/3*pi); 


omega = pi;

MBC = 2/3 *[0.5 * ones(1,3); cos(omega), cos(omega+2*pi/3), cos(omega+2*pi/3);... 
    sin(omega), sin(omega+2*pi/3), sin(omega+2*pi/3)];

M_0_cos_sin = nan(3,lenT);
for idx = 1: length(t)
    M_0_cos_sin(:,idx) = MBC * M_flap(:,idx);
end


figure;
subplot(2,1,1)
plot(t,M_flap); 
grid on; axis tight;
legend('M1',"M2","M3")

subplot(2,1,2)
plot(t,M_0_cos_sin); 
legend('M0',"MC","MS")
grid on; axis tight;


