function SBMLUnitDefinition = UnitDefinition_setName(SBMLUnitDefinition, name)
%
%   UnitDefinition_setName 
%             takes  1) an SBMLUnitDefinition structure 
%             and    2) a string representing the name to be set
%
%             and returns 
%               the unitDefinition with the name set
%
%       SBMLUnitDefinition = UnitDefinition_setName(SBMLUnitDefinition, 'name')

%  Filename    :   UnitDefinition_setName.m
%  Description :
%  Author(s)   :   SBML Development Group <sbml-team@caltech.edu>
%  $Id: UnitDefinition_setName.m 7155 2008-06-26 20:24:00Z mhucka $
%  $Source v $
%
%<!---------------------------------------------------------------------------
% This file is part of SBMLToolbox.  Please visit http://sbml.org for more
% information about SBML, and the latest version of SBMLToolbox.
%
% Copyright 2005-2007 California Institute of Technology.
% Copyright 2002-2005 California Institute of Technology and
%                     Japan Science and Technology Corporation.
% 
% This library is free software; you can redistribute it and/or modify it
% under the terms of the GNU Lesser General Public License as published by
% the Free Software Foundation.  A copy of the license agreement is provided
% in the file named "LICENSE.txt" included with this software distribution.
% and also available online as http://sbml.org/software/sbmltoolbox/license.html
%----------------------------------------------------------------------- -->



% check that input is correct
if (~isstruct(SBMLUnitDefinition))
    error(sprintf('%s', ...
      'argument must be an SBML UnitDefinition structure'));
end;
 
[sbmlLevel, sbmlVersion] = GetLevelVersion(SBMLUnitDefinition);

if (~isSBML_UnitDefinition(SBMLUnitDefinition, sbmlLevel, sbmlVersion))
    error(sprintf('%s\n%s', 'UnitDefinition_setName(SBMLUnitDefinition, name)', 'first argument must be an SBML unitDefinition structure'));
elseif (~ischar(name))
    error(sprintf('UnitDefinition_setName(SBMLUnitDefinition, name)\n%s', 'second argument must be a string representing the name of the unitDefinition'));
end;

SBMLUnitDefinition.name = name;