function [logL0] = L0_test(dct,F,omega)

% 
% Copyright (C) 2017 Cecilia Pasquini, Giulia Boato and Fernando Pèrez-Gonzàlez,       
% Department of Information Engineering and Computer Science (DISI) - University of Trento                      
% via Sommarive 9 - I-38123 - Trento, Italy   
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
% 
% 
% Additional permission under GNU GPL version 3 section 7
%
%
% If you use part of this software, please cite the following publication:
% -------------------------------------------------------------------------
% C. Pasquini, G. Boato and F. Pèrez-Gonzàlez, "Statistical detection of JPEG 
% traces in digital images in uncompressed formats", IEEE Transactions on 
% Information Forensics and Security, vol. 12, no. 12. pp. 2890-2905, 2017.
% -------------------------------------------------------------------------
%
% Contact: cecilia.pasquini@uibk.ac.at


aux = izigzag(1:64,8,8);

for f_ind=1:length(F)

[f1,f2] = find(aux==F(f_ind));

% extract all the DCT coefficients
coeffs = dct(f1:8:end,f2:8:end); coeffs=coeffs(:);
M=numel(coeffs);
[r] = bf_average_omega(coeffs,omega);
BF_a(f_ind,:) = r;
end

T=numel(F);

logL0 = T*log(2*M) + sum(log(BF_a)) - M*sum(BF_a.^2); 

end



function [av,z]=bf_average_omega(t,w)

t=abs(t);
nonzero=find(t>0);
elements=zeros(size(t));
elements(nonzero)=t(nonzero).^(-1i*w/log(10));

% elements(nonzero)=exp(-j*2*pi*n*log10(t(nonzero)));

z=sum(elements)/length(t);
av=abs(z);

end

