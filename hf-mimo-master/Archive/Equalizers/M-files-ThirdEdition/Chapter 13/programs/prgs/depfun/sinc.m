function y=sinc(x)
%SINC Sin(pi*x)/(pi*x) function.
%   SINC(X) returns a matrix whose elements are the sinc of the elements 
%   of X, i.e.
%        y = sin(pi*x)/(pi*x)    if x ~= 0
%          = 1                   if x == 0
%   where x is an element of the input matrix and y is the resultant
%   output element.
%
%   See also SQUARE, SIN, COS, CHIRP, DIRIC, GAUSPULS, PULSTRAN, RECTPULS,
%   and TRIPULS.

%   Author(s): T. Krauss, 1-14-93
%   Copyright 1988-2001 The MathWorks, Inc.
%       $Revision: 1.6 $  $Date: 2001/04/02 20:20:54 $

y=ones(size(x));
i=find(x);
y(i)=sin(pi*x(i))./(pi*x(i));
