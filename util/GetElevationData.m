%% Code Information
%*************************************************************************
%Stanford GPS

%Function Description: gathers elevation data from api and existing geotiff
%directory to create elevation mesh and georeference objects

%*************************************************************************


function [mosaicZ,mosaicRZ]=GetElevationData(boxlat,boxlon,username,password)
    %import module for api
    py.importlib.import_module('download_data');
    %find directory where geotiff files are stored, if empty, call api
    [~,geotiff_dir]=BasemapDir();
    %create empty cell array for elevation data
    lat=floor(boxlat(1)):floor(boxlat(2));
    lon=floor(boxlon(1)):floor(boxlon(2));
    elev_data=cell(numel(lat),numel(lon));
    geo_data=cell(numel(lat),numel(lon));
    %check if files are present, if so, add to grid layout
    files={geotiff_dir.name};
    num_files=numel(files);
    for i=1:num_files
        [Z,RZ]=readgeoraster(files{i},'OutputType','double');
        if (boxlat(1)||boxlat(2)>=RZ.LatitudeLimits(1)) && ...
                (boxlat(1)||boxlat(2)<=RZ.LatitudeLimits(2)) && ...
            (boxlon(1)||boxlon(2)>=RZ.LongitudeLimits(1)) && ...
            (boxlon(1)||boxlon(2)<=RZ.LongitudeLimits(2))
            lat_ind=find(lat==round(RZ.LatitudeLimits(1)));
            lon_ind=find(lon==round(RZ.LongitudeLimits(1)));
            elev_data{lat_ind,lon_ind}=Z;
            geo_data{lat_ind,lon_ind}=RZ;
        else
            continue
        end
    end
    %now run through files that are missing, call api
    [row,col]=find(cellfun(@isempty,elev_data));
    for j=1:numel(row)
        select_grid_lat=lat(row(j));
        select_grid_lon=lon(col(j));
        select_boxlat=[select_grid_lat+.1 select_grid_lat+.9];
        select_boxlon=[select_grid_lon+.1 select_grid_lon+.9];
        [python_geo_name]=py.download_data.main(select_boxlat,...
            select_boxlon,username,password);
        [~,geotiff_dir]=BasemapDir();
        files={geotiff_dir.name};
        [elev_data{row(j),col(j)},geo_data{row(j),col(j)}]=readgeoraster(...
            files{files==string(python_geo_name)},'OutputType','double');
    end
    %combine georaster files 
    latlimits=[floor(boxlat(1)) ceil(boxlat(2))];
    lonlimits=[floor(boxlon(1)) ceil(boxlon(2))];
    [~,grid_col]=size(elev_data);
    cols_cell=cell(1,grid_col);
    %flip laterally (north and south)
    elev_data=flip(elev_data,1);
    for k=1:grid_col
        cols_cell{k}=vertcat(elev_data{:,k});
    end
    mosaicZ=horzcat(cols_cell{:});
    mosaicRZ = georefpostings(latlimits,lonlimits,size(mosaicZ));
    mosaicRZ.ColumnsStartFrom = 'north';
    mosaicRZ.RowsStartFrom='west';
end

%% Local Functions
%Make directory to place geotiff files
function [path,d]=BasemapDir()
    if ~exist('geotif')
        mkdir geotif
    end
    path_prop=what('geotif');
    addpath('geotif')
    path=path_prop.path;
    d=dir(path);
    d=d(~ismember({d.name},{'.','..'}));
end
