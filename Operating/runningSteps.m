%% running steps

orderIndex = choiceList('Select a scenario','Choose one of the scenarios and follow the instructions.',{'Manual Input','Only One Step','All But One','All the steps together','Business as Usual', 'Sensitivity Analysis', 'All the steps together - new scenario table', 'Sensitivity Analysis +- 10%'});
if (orderIndex ~= 1 && orderIndex ~= 4 && orderIndex ~= 5  && orderIndex ~= 7 &&  orderIndex ~= 8)
    scenarioIndex = choiceList('Select a scenario','Choose one of the scenarios',{'S1','S2','S3','Busnness as Usual','Othen_OnlyOne','Othen_AllButOne','Moderate','Advanced'});
end
switch orderIndex

    case 1 %% Manual changes
        ManualScenariosTable = ManualChangesByScenarios(DataBase);
        [EmissionsByYearsCurrent, ConsumptionAmountsCurrent] = FullScenario(DataBase, ManualScenariosTable, Years);
        EmissionsSumCurrent = EmissionsSumCalcOnlyOneStep(EmissionsByYearsCurrent,Years);
        disp('Manual changes');

    case 2 %% Only one step
        % each iteration calculates scenario i.
        for i = 1:ScenarioNumber
            OnlyOneStepScenariosTable = AllButOneChangesByScenarios(DataBase, i, Years, ScenariosAndValues{:,scenarioIndex}, 'OnlyOne', true);
            % returns a table where only the i row changes

            [population] = populationCal(OnlyOneStepScenariosTable);
            [EmissionsByYears, ConsumptionAmounts, Resources, WaterFromFood,ElectricityBySources] = FullScenario(DataBase, OnlyOneStepScenariosTable, Years,population,orderIndex,i);
            EmissionsSumCurrentBase = EmissionsSumCalcOnlyOneStep(EmissionsByYears,Years);
            GlobalLocalEmissions = CalcGlobalLocal(EmissionsByYears);
            GlobalDiff = sum(GlobalLocalEmissions{2,width(GlobalLocalEmissions)}{1,:}) - sum(GlobalLocalEmissions{2,1}{1,:});
            % total emissions of 2050 minus total of 2017 - GLOBAL
            LocalDiff = sum(GlobalLocalEmissions{1,width(GlobalLocalEmissions)}{1,:}) - sum(GlobalLocalEmissions{1,1}{1,:});
            % total emissions of 2050 minus total of 2017 - LOCAL

            [WaterSumCurrent, GlobalWaterDiff, LocalWaterDiff] = WaterSumCalcOnlyOne(ConsumptionAmounts, WaterFromFood,i);
            [AreaSumCurrent, GlobalAreaDiff, LocalAreaDiff] = AreaSumCalcOnlyOne(Resources);

            %OnlyOneAnalysis{i,1} = EmissionsSumCurrentBase(1);
            OnlyOneAnalysis{i,1} = GlobalDiff+LocalDiff;
            OnlyOneAnalysis{i,2} = GlobalDiff;
            OnlyOneAnalysis{i,3} = LocalDiff;
            OnlyOneAnalysis{i,4} = WaterSumCurrent;
            OnlyOneAnalysis{i,5} = GlobalWaterDiff;
            OnlyOneAnalysis{i,6} = LocalWaterDiff;
            OnlyOneAnalysis{i,7} = AreaSumCurrent;
            OnlyOneAnalysis{i,8} = GlobalAreaDiff;
            OnlyOneAnalysis{i,9} = LocalAreaDiff;
        end
        disp('Only one step');

    case 3 %% All steps but one
        AllButOneScenariosTable = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,scenarioIndex});
        % will return 19X34 table, each cell is the change of this factor
        % for that year, when 2050 is dictated by "the three scenarios".
        [population] = populationCal(AllButOneScenariosTable);
        [EmissionsByYearsFull, ConsumptionAmountsFull, ResourcesFull, WaterFromFoodFull,ElectricityBySources] = FullScenario(DataBase, AllButOneScenariosTable, Years, population,orderIndex,0);
        GlobalLocalEmissionsFull = CalcGlobalLocal(EmissionsByYearsFull);
        for i = 1:ScenarioNumber
            AllButOneScenariosTable = AllButOneChangesByScenarios(DataBase, i, Years, ScenariosAndValues{:,scenarioIndex});
            [population] = populationCal(AllButOneScenariosTable);
            [EmissionsByYears, ConsumptionAmounts, Resources, WaterFromFood,ElectricityBySources] = FullScenario(DataBase, AllButOneScenariosTable, Years, population,orderIndex,0);
            CurrentEmissions = EmissionsSumCalcAllButOne(EmissionsByYears, EmissionsByYearsFull,Years);
            GlobalLocalEmissions = CalcGlobalLocal(EmissionsByYears);
            GlobalDiff = sum(GlobalLocalEmissionsFull{2,width(GlobalLocalEmissionsFull)}{1,:}) - sum(GlobalLocalEmissions{2,width(GlobalLocalEmissions)}{1,:});
            LocalDiff = sum(GlobalLocalEmissionsFull{1,width(GlobalLocalEmissionsFull)}{1,:}) - sum(GlobalLocalEmissions{1,width(GlobalLocalEmissions)}{1,:});
            [CurrentWater, GlobalWaterDiff, LocalWaterDiff] = WaterSumCalcAllButOne(ConsumptionAmounts, ConsumptionAmountsFull, WaterFromFood, WaterFromFoodFull);
            [CurrentArea, GlobalAreaDiff, LocalAreaDiff] = AreaSumCalcAllButOne(Resources, ResourcesFull);

            %AllButOneAnalysis{i,1} = CurrentEmissions;
            AllButOneAnalysis{i,1} = GlobalDiff+LocalDiff;
            AllButOneAnalysis{i,2} = GlobalDiff;
            AllButOneAnalysis{i,3} = LocalDiff;
            AllButOneAnalysis{i,4} = CurrentWater;
            AllButOneAnalysis{i,5} = GlobalWaterDiff;
            AllButOneAnalysis{i,6} = LocalWaterDiff;
            AllButOneAnalysis{i,7} = CurrentArea;
            AllButOneAnalysis{i,8} = GlobalAreaDiff;
            AllButOneAnalysis{i,9} = LocalAreaDiff;
        end
        disp('All steps but one');

    case 4  %% All the steps together
        % calculates 3 times: for BAU, MODERATE, ADVANCED
        % first table: change in precentage for each parameter by the years.
        % second table: population size per year, seperationg israel and the palestinians.
        % returns: total Co2 by category, amounts of water/fuels/construction materials, all other resources by category, water for food.

        [FullScenariosTableBAU] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,4}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableBAU);
        [DataBase.NZOscenarioTable,NZOscenarioBAU,accessToken] = nzoFunction('B.A.U',DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime);
        [EmissionsByYearsBAU, ConsumptionAmountsBAU, ResourcesBAU, WaterFromFoodBAU,ElectricityBySourcesBAU] = FullScenario(DataBase, FullScenariosTableBAU,Years,population,orderIndex,0,'B.A.U');

        [FullScenariosTableMOD] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,7}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableMOD);
        [DataBase.NZOscenarioTable,NZOscenarioMOD,accessToken] = nzoFunction('MOD',DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime);
        [EmissionsByYearsMOD, ConsumptionAmountsMOD, ResourcesMOD, WaterFromFoodMOD,ElectricityBySourcesMOD] = FullScenarioCompare(DataBase, FullScenariosTableMOD,Years,population,WaterFromFoodBAU,orderIndex,'MOD');

        [FullScenariosTableADV] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableADV);
        [DataBase.NZOscenarioTable,NZOscenarioADV,accessToken] = nzoFunction('ADV', DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime);
        [EmissionsByYearsADV, ConsumptionAmountsADV, ResourcesADV, WaterFromFoodADV,ElectricityBySourcesADV] = FullScenarioCompare(DataBase, FullScenariosTableADV,Years,population,WaterFromFoodBAU,orderIndex,'ADV');

        [FullScenariosTableADV] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableADV);
        [DataBase.NZOscenarioTable,NZOscenarioADV_NUC,accessToken] = nzoFunction('ADV+NUC', DataBase,clientID, sheetID,clientSecret,refreshToken, script_id, accessToken,lastTokenTime);
        [EmissionsByYearsADV_NUC, ConsumptionAmountsADV_NUC, ResourcesADV_NUC, WaterFromFoodADV_NUC,ElectricityBySourcesADV_NUC] = FullScenarioCompare(DataBase, FullScenariosTableADV,Years,population,WaterFromFoodBAU,orderIndex,'ADV+NUC');
 
      
        
        disp('All the steps together');


    case 5 %% Buisness as usual
        FullBAUScenariosTable = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,4});
        [EmissionsByYearsBAU, ConsumptionAmountsBAU,ResourcesBAU, WaterFromFoodBAU,ElectricityBySourcesBAU] = FullScenario(DataBase, FullBAUScenariosTable, Years,population,orderIndex,0);

        YearlyEmissionsBAU = YearlySumCalc(EmissionsByYearsBAU);
        disp('Buisness as usual');


    case 6 %% SensitivityAnalysis
        SensitivityAnalysisCell = cell(3, 3*3);
        l = 1; %index that marks in which combination we are (for 3 options of 2 categories)
        for i = 1:3
            for j = 1:3
                % in each iteration: changing the pop-growth to 0/45%/90%
                ScenariosAndValues{1,scenarioIndex} =  PopulationGrowth{1,i};
                % in each iteration: changing the electricity consumption to 0/20%/41%
                ScenariosAndValues{2,scenarioIndex} =  ElectricityPerCapita{1,j};
                % in each iteration: changing the desalination to 0/132%/264%, matching the population growth.
                ScenariosAndValues{3,scenarioIndex} =  DesalinatedWater{1,i};
                ScenariosTable = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,scenarioIndex}, 'MileStones', false);
                % ScenariosTable will be the same as the THREE SCENARIOS
                % table, except rows 1-3 (poplation, electricity, desalination)
                [population] = populationCal(ScenariosTable);
                [EmissionsTable, ConsumptioTable, Resources] = FullScenario(DataBase, ScenariosTable, Years,population,orderIndex,0);
                SensitivityAnalysisCell{1, l} = EmissionsTable;
                SensitivityAnalysisCell{2, l} = ConsumptioTable;
                SensitivityAnalysisCell{3, l} = Resources;
                l = l+1;
            end
        end
        disp('SensitivityAnalysis');

    case 7  % All the steps together - WITH NEW SCENARIO VALUES
        % first table: change in precentage for each parameter by the years.
        % second table: population size per year, seperationg israel and the palestinians.
        % returns: total Co2 by category, amounts of water/fuels/construction materials, all other resources by category, water for food.

        % NO POLICY
        [FullScenariosTableBAU] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,4}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableBAU);
        [EmissionsByYearsBAU, ConsumptionAmountsBAU, ResourcesBAU, WaterFromFoodBAU,ElectricityBySourcesBAU] = FullScenario(DataBase, FullScenariosTableBAU,Years,population,orderIndex,0);

        % NEW POLICY
        Years = 19; % for 2035
        NewValues = readtable("The Three Scenarios.xlsx", 'Sheet', 'Scenarios', 'Range', 'K2:K20', 'ReadRowNames', false, 'ReadVariableNames', false);
        ScenariosAndValues{:, 8} = NewValues{:,:};
        [FullScenariosTableADV] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
        [population] = populationCal(FullScenariosTableADV);
        [EmissionsByYearsADV, ConsumptionAmountsADV, ResourcesADV, WaterFromFoodADV,ElectricityBySourcesADV] = FullScenarioCompare(DataBase, FullScenariosTableADV,Years,population,WaterFromFoodBAU,orderIndex);

    case 8 % Sensitivity Analysis - +- 10%

        % preperations: define the new scenario precentages and the year.
        Years = 19; % for 2035
        NewValues = readtable("The Three Scenarios.xlsx", 'Sheet', 'Scenarios', 'Range', 'K2:K20', 'ReadRowNames', false, 'ReadVariableNames', false);
        ScenariosAndValues{:, 8} = NewValues{:,:};
        RelevantScenarios = [1, 2, 3, 4, 5, 6, 7, 8, 12, 13, 14, 15, 16, 17, 19];  % only choosing interesting scenarios

        rowNames = ScenariosAndValues.Properties.RowNames;
        SensitivityAnalysisCell = cell(2, height(ScenariosAndValues));

        % SensitivityAnalysisCell has 12 columns, each of them represent a different scenario.
        % the upper row is Original_Precentage - 10%_Bigger
        % the lower row is Original_Precentage - 10%_Smaller
        for i = 1:length(RelevantScenarios)

            ScenarioIndex = RelevantScenarios(i); % iterarting through all the relevant scenarios
            OriginalPrecentage = ScenariosAndValues{ScenarioIndex, 8}; % saving the original value

            % running FULL SCENARIO 3 times: as is, +10%, -10%.
            [FullScenariosTableBAU] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
            [population] = populationCal(FullScenariosTableBAU);
            [EmissionsByYearsBAU, ConsumptionAmountsBAU, ResourcesBAU, WaterFromFoodBAU,ElectricityBySourcesBAU] = FullScenario(DataBase, FullScenariosTableBAU,Years,population,orderIndex,0);
            TotalEmission1 = CalcUpDownStream(EmissionsByYearsBAU);

            ScenariosAndValues{ScenarioIndex, 8} = OriginalPrecentage * 1.1; % new calculation for +10%
            [FullScenariosTableMOD] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
            [population] = populationCal(FullScenariosTableMOD);
            [EmissionsByYearsMOD, ConsumptionAmountsMOD, ResourcesMOD, WaterFromFoodMOD,ElectricityBySourcesMOD] = FullScenario(DataBase, FullScenariosTableMOD,Years,population,orderIndex,0);
            TotalEmission2 = CalcUpDownStream(EmissionsByYearsMOD);

            ScenariosAndValues{ScenarioIndex, 8} = OriginalPrecentage * 0.9 ; % new calculation for -10%
            [FullScenariosTableADV] = AllButOneChangesByScenarios(DataBase, 0, Years, ScenariosAndValues{:,8}, 'MileStones', false);
            [population] = populationCal(FullScenariosTableADV);
            [EmissionsByYearsADV, ConsumptionAmountsADV, ResourcesADV, WaterFromFoodADV,ElectricityBySourcesADV] = FullScenario(DataBase, FullScenariosTableADV,Years,population,orderIndex,0);
            TotalEmission3 = CalcUpDownStream(EmissionsByYearsADV);

            BiggerMinusOriginal = TotalEmission2 - TotalEmission1;
            OriginalMinusSmaller = TotalEmission1 - TotalEmission3;

            ScenariosAndValues{ScenarioIndex, 8} = OriginalPrecentage ; % RESET
            SensitivityAnalysisCell{1, ScenarioIndex} = BiggerMinusOriginal;
            SensitivityAnalysisCell{2, ScenarioIndex} = OriginalMinusSmaller;

            disp('SensitivityAnalysis');

        end

        SensitivityAnalysisTable = cell2table(SensitivityAnalysisCell);
        SensitivityAnalysisTable.Properties.VariableNames = rowNames;
        SensitivityAnalysisTable.Properties.RowNames = {'BiggerMinusOriginal', 'OriginalMinusSmaller'};
        SensitivityAnalysisCell = table2cell(SensitivityAnalysisTable);


end

beep;




