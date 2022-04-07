/*
Covid 19 Data Exploration 
Skills used: Joins, Aggregate Functions, Temp Tables, Creating Views, Converting Data Types
*/

Select *
From Project..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From Project..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Project..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Project..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Project..CovidDeaths
--Where location like '%states%'
Group by Location, Population
order by PercentPopulationInfected desc

--Death rate
select location,max(cast(total_deaths as int)) as totaldeaths,(max(cast(total_deaths as int))/max(total_cases))*100 as death_rate
from CovidDeaths
--where location like '%india%'
group by location
order by 3 desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Project..CovidDeaths
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

select location,max(cast(total_deaths as int)) as totaldeaths,(max(cast(total_deaths as int))/max(total_cases))*100 as death_rate
from CovidDeaths
where continent is null
group by location
order by 2 desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Project..CovidDeaths
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2

--GLOBAL NUMBERS BY EACH DAY

select date,SUM(new_cases) as newcases,sum(cast(new_deaths as int))as newdeaths,(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_rate
from CovidDeaths
where continent is not null
group by date
order by date

--total gobal numbers in the year 2021
select sum(new_cases) as newcases,sum(cast(new_deaths as int))as newdeaths,(sum(cast(new_deaths as int))/sum(new_cases))*100 as death_rate
from coviddeaths
where continent is not null and date between '2021-01-01' and '2022-12-31'


--total vaccinations vs fully vaccinated
select location,date,total_vaccinations,people_fully_vaccinated 
from covidvaccinations 
where total_vaccinations is not null and continent is not null
order by 1,2

--total_vaccinations vs population
select dea.location,dea.date,dea.population,vac.people_fully_vaccinated,(vac.people_fully_vaccinated/dea.population)*100 as per_of_people 
from covidvaccinations vac
join coviddeaths dea 
on vac.location=dea.location and vac.date=dea.date
where dea.continent is not null and vac.people_fully_vaccinated is not null
order by 1,2


--getting total vaccinations by new vaccinations
select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations, 
sum(convert(bigint,vac.new_vaccinations)) 
over (partition by dea.location order by dea.location, dea.date) as total_vaccinated
from covidvaccinations vac
join coviddeaths dea on vac.location=dea.location and vac.date=dea.date
where dea.continent is not null and vac.new_vaccinations is not null and dea.location like '%india%'
order by 2,3



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null



--percentage of people vaccinated
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated
order by 1,2 ,3




-- Creating View to store data for later visualizations


create View PercentPopulationVaccinated 
with encryption
as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From Project..CovidDeaths dea
Join Project..covidvaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *from PercentPopulationVaccinated



