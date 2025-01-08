function [ElectricityManufacturingEmissions, FuelAmounts] = CalcElectricityManufacturing(Data, CurrentYearManufacturing, PreviousYearElectricity, ElectricityConsumptionPercentages, Year,scenarioName) 

%% Taking into account the changes in PV emissions by the year.
CurrentElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year);
if Year ~= 1 
    PreviousElectricityConsumptionPercentages = ElectricityConsumptionPercentages(:, Year-1); 
end


%% Read files
EmissionsCoefficientsUpstream = Data.EmissionsCoefficientsUpstreamElectricity;
EmissionsCoefficientsForPv = Data.EmissionsCoefficientsForPv;
NZOscenarioTable = Data.NZOscenarioTable;
EmissionsCoefficientsForStorage = Data.EmissionsCoefficientsForStorage;

%% Create Table
RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply & Sewage Treatment', 'Total'};
CurrentYearTable = array2table(zeros(7,6), 'RowNames', RowNames);
CurrentYearTable.Properties.VariableNames = {'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut','KWh From Nucler'};
%% Create Table For current year
RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply & Sewage Treatment', 'Total'};
CurrentYearTable = array2table(zeros(7,6), 'RowNames', RowNames);
CurrentYearTable.Properties.VariableNames ={'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut','KWh From Nucler'};

% Consumption Table - Current year
Total=0;
for j=2:width(CurrentYearTable) %% 1-6
    for i=1:height(CurrentYearTable)-1 %% 1-6
        CurrentYearTable{i,j-1} = CurrentYearManufacturing(i)*CurrentElectricityConsumptionPercentages(j-1);
        Total = Total + CurrentYearTable{i,j-1};
    end
    CurrentYearTable{7,j-1} = Total;
    Total=0;
end
if Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName} > 0 && Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName}*0.9*8760 <= CurrentYearTable{7,3}
    CurrentYearTable{7,6} = Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName}*0.9*8760; %Installed MW* Utilized* Hours per year . There is no need to change to KW because the answer is in tons.
    CurrentYearTable{7,3} = CurrentYearTable{7,3} - CurrentYearTable{7,6}; 
end

%% Create Table for previous year
% (if its the first year creating a fictive tavle of zeros 
RowNames = {'Home', 'Public & Commercial', 'Industrial', 'Other', 'Transportation', 'Water Supply & Sewage Treatment', 'Total'};
PrevYearTable = array2table(zeros(7,6), 'RowNames', RowNames);
PrevYearTable.Properties.VariableNames ={'KWh From Coal', 'KWh From Natural Gas', 'KWh From Renewable Energies', 'KWh From Soler', 'KWh From Mazut','KWh From Nucler'};
if Year ~= 1 
    % Consumption Table - prev year
    Total=0;
    for j=2:width(PrevYearTable) %% 1-6
        for i=1:height(PrevYearTable)-1 %% 1-6
            PrevYearTable{i,j-1} = PreviousYearElectricity(i)*PreviousElectricityConsumptionPercentages(j-1);
            Total = Total + PrevYearTable{i,j-1};
        end
     PrevYearTable{7,j-1} = Total;
     Total=0;
    end
end
if Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName} > 0 && Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName}*0.9*8760 <= PrevYearTable{7,3}
    PrevYearTable{7,6} = Data.InstalledCapacityForOutsideMod{'Nuclear mw',scenarioName}*0.9*8760;
    PrevYearTable{7,3} = PrevYearTable{7,3} - PrevYearTable{7,6}; 
end
%% Electricity Manufacturing Coefficients
% (ton of Coal, Soler, Gas etc' per KWH)
ElectrictyManufacturingCoefficients = Data.ElectrictyManufacturingCoefficients;

%% Fuel Amounts
ElectricityForFules = CurrentYearTable{7,1:width(CurrentYearTable)};
ElectricityForFules(6) = []; %removing nucler
ElectricityForFules(3) = []; %removing renewables
FuelAmounts = ElectricityForFules.*ElectrictyManufacturingCoefficients;
CrudeOilToFuelRatio = Data.CrudeOilToFuelRatio;
FuelAmounts(end+1) = (FuelAmounts(3)+FuelAmounts(4))*CrudeOilToFuelRatio;

%% fuel amounts for electricity
FuelAmounts = array2table(FuelAmounts, 'RowNames', {'Amount'});
FuelAmounts.Properties.VariableNames = {'Coal', 'Natural Gas','Diesel', 'Mazut','Crude Oil'};

%% Total Emissions Per Current Year
RowNames = {'Coal', 'Natural Gas','Soler', 'Mazut', 'Crude Oil', 'PV', 'Storage Energy', 'Nucler'};
TotalEmissionsPerYear = array2table(zeros(8,7), 'RowNames', RowNames);
for i = 1:(height(EmissionsCoefficientsUpstream)+2) %% 1-6 + 1 to storage + 1 to nucler
    for  j = 1:width(EmissionsCoefficientsUpstream) %% 1-7
        if(i == 6) % dealing with PV
            if (j==2 || j==7) % only relevant for CO2 / CO2E
                Delta = CurrentYearTable{7,3} - PrevYearTable{7,3}; % extra KHW consumption for this year
                if Delta < 0
                    Delta = 0;
                end
                if Year == 1 
                    Delta = Delta * 16/100; 
                end
     % without the last if, the model calculates as all the panels were installed in 2017. since from 2016 to 2017,
     % the installed KW changed from 5% to 5.8%, we can assume that the delta is 0.8/5 
            TotalEmissionsPerYear{i,j} = Delta * EmissionsCoefficientsForPv{Year, 2}/1000000 * 25; %tons (25 is because the panels works for 25 years)
            % TotalEmissionsPerYear{i,j} = CurrentYear{7,3}*EmissionsCoefficientsUpstream(i,j)/1000000; % tons
            end
       elseif (i < 6)   % rest of the energy sources   
            TotalEmissionsPerYear{i,j} = EmissionsCoefficientsUpstream(i,j)*FuelAmounts{1,i}/1000; %tons
       end   
       if(i == 7 && Year >= 4) % storage from 2020 nzo model
          if  Year == 4
              TotalEmissionsPerYear{i,7} = NZOscenarioTable{Year,4}*EmissionsCoefficientsForStorage{Year,2};
          else
              storageGap = NZOscenarioTable{Year-3,4}-NZOscenarioTable{(Year-4),4};
              TotalEmissionsPerYear{i,7} = storageGap*EmissionsCoefficientsForStorage{Year,2};
          end
       end
        if i == 8 % nucler
            TotalEmissionsPerYear{i,7} = CurrentYearTable{7,6}*0.015;%   * 0.015 grams co2e per hour MWH
        end
    end    
end 

TotalEmissionsPerYear.Properties.VariableNames = {'CH4', 'CO2','Hydroflour Carbon', 'Air Pollutants','Mining Waste', 'Waste Water', 'CO2 Equivalent'};
ElectricityManufacturingEmissions = TotalEmissionsPerYear;
FuelAmounts = removevars(FuelAmounts, 'Crude Oil');
end
