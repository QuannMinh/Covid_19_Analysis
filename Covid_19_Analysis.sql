Select location, date, total_cases, total_deaths, population 
from dbo.CovidDeaths$
order by 1,2

-- The death percentage
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
from dbo.CovidDeaths$
order by 1,2


-- The percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as covid 
from dbo.CovidDeaths$
order by 1,2

-- The highest infection rate compared to the population
select location, population, MAX(total_cases) as HighestInfectionCount, MAX(total_cases/population)*100 as PercentPopulationInfected 
from dbo.CovidDeaths$
group by location, population
order by PercentPopulationInfected desc

-- The highest death count compared to population
select location, population, MAX(cast(total_deaths as int)) as HighestDeathCount -- Why cast ??? - data type is wrong (nvarchar(225): can be number, character
from dbo.CovidDeaths$
where continent is not null
group by location, population
order by HighestDeathCount desc

-- The highest death count by continent
select location, MAX(cast(total_deaths as int)) as HighestDeathCount 
from dbo.CovidDeaths$
where continent is null
group by location
order by HighestDeathCount desc

/*select continent, MAX(cast(total_deaths as int)) as HighestDeathCount 
from dbo.CovidDeaths$
where continent is not null
group by continent
order by HighestDeathCount desc*/

-- Global numbers 
select date, sum(new_cases) as totalcases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from dbo.CovidDeaths$
where continent is not null
group by date 
order by 1

-- Using window function to find out numbers of people vaccinated
with cte --(continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) 
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths$ dea join [dbo].[CovidVaccinations$] vac
on dea.date = vac.date and dea.location = vac.location
where dea.continent is not null
)
-- Use CTE to calculate the percentage of people vaccinated
select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage from cte

-- Create table 
Drop table if exists #PercentPeopleVaccinated
Create table #PercentPeopleVaccinated
(
Continent nvarchar(225),
Location nvarchar(225),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPeopleVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths$ dea join [dbo].[CovidVaccinations$] vac
on dea.date = vac.date and dea.location = vac.location
--where dea.continent is not null

select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage from #PercentPeopleVaccinated

-- Create view for later visualization
Create view PercentPeopleVaccinated as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) Over (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from dbo.CovidDeaths$ dea join [dbo].[CovidVaccinations$] vac
on dea.date = vac.date and dea.location = vac.location 