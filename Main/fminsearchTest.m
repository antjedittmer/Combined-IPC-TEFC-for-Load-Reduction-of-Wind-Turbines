clear all


%f = @(x,a)100*(x(2) - x(1)^2)^2 + (a-x(1))^2;

%a = 3;

%fun = @(x)f(x,a);


%x0 = [-1,1.9];
%x = fminsearch(@optimierung,x0)

%options = optimset('PlotFcns',@optimplotfval,'Display','iter','MaxIter',20);
options = optimset('PlotFcns',@optimplotfval,'Display','iter','MaxIter',2, 'MaxFunEvals', 2);
a = 3;
fun = @(x)optimierung(a,x);

x0 = [-1,1.9];
x = fminsearch(fun,x0,options)


function [a1, a2] = optimierung(a,x)


a1 = 100*(x(2) - x(1)^2)^2 + (a-x(1))^2;

a2 = 10*x(1);
end
