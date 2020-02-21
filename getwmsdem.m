%Download DEM to MATLAB using NASA wms server - based on MATLAB official
%suggestion https://www.mathworks.com/help/map/ref/wmsread.html
%
%Inputs
%latlim: latitude limits (bounding box) in degrees [lower upper] - can be
%obtained from google maps
%lonlim: longitude limits (bounding box) in degrees [left right] 
%demcode: code for desired DEM type, see below
%
%Outputs:
%LAT=latitude grid
%LON=longitude grid
%Z1=DEM
%
%Example:[Z1,LON,LAT]=getwmsdem([37.4 37.8],[-119.3 -118.6],9); (DEM for
%Bishop Tuff region of CA) using option 9 (SRTM3v4.1)
%
% supported demcodes and max latlon limits are:           
%           Index: 1
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'SRTM30 with Bathymetry (900m) merged with global ASTER (30m)'
%        LayerName: 'EarthAsterElevations30m'
%           Latlim: [-90.0000 90.0000]
%           Lonlim: [-180.0000 180.0000]
% 
%            Index: 2
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'USGS NED 30m'
%        LayerName: 'NED'
%           Latlim: [-14.5000 66.0001]
%           Lonlim: [-171.0000 163.5000]
%
% 
%            Index: 5
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'aster_30m'
%        LayerName: 'aster_30m'
%           Latlim: [-90.0000 90.0000]
%           Lonlim: [-180.0000 180.0000]
% 
%            Index: 6 (default)
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'SRTM30 with Bathymetry (900m) merged with global ASTER (30m) and USGS NED (10m)'
%        LayerName: 'mergedAsterElevations'
%           Latlim: [-90.0000 90.0000]
%           Lonlim: [-180.0000 180.0000]
% 
%            Index: 9
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'SRTM3 V4.1'
%        LayerName: 'srtm3'
%           Latlim: [-60.0000 60.0000]
%           Lonlim: [-180.0000 180.0000]
% 
%            Index: 10
%      ServerTitle: 'NASA WorldWind WMS'
%        ServerURL: 'http://www.nasa.network.com/elev?'
%       LayerTitle: 'SRTM30 Plus'
%        LayerName: 'srtm30'
%           Latlim: [-90.0000 90.0000]
%           Lonlim: [-180.0000 180.0000]
% 




function [Z1,LON,LAT] = getwmsdem(latlim,lonlim,demcode)

if nargin<=2
    demcode=6;
end


switch demcode
    case 1
        res=1;
    case 2
        res=1;
    case 5
        res=1;
    case 6
        res=1;
    case 9
        res=3;
    case 10
        res=30;
    otherwise
        error('Unsupported DEM format')
        
        
    
end

 [LON,LAT]=meshgrid(lonlim(1)+res/3600:res/3600: ...
        lonlim(2),latlim(1)+res/3600:res/3600: ...
        latlim(2)); 
    
%WMS server does not like it if grid dimension is greater than 1 degree
%For high resolution DEMs, so we have to determine the size.  If any
%dimension is greater than 1 degree we have to get the "tiles" iteratively.

if demcode==10||res==30||(lonlim(2)-lonlim(1)<=1&&latlim(2)-latlim(1)<=1)
    wldwind = wmsfind('nasa.network*elev', 'SearchField', 'serverurl');
    srtmplus = wldwind(demcode);
    samplesPerInterval = dms2degrees([0 0 res]);
    imageFormat = 'image/bil';
    [Z1, R1] = wmsread(srtmplus, 'Latlim', latlim, ...
    'Lonlim', lonlim, 'ImageFormat', imageFormat, ...
    'CellSize', samplesPerInterval);


else
    tlonlim=lonlim;
    tlatlim=latlim;
    Z1=[];
    for i=1:abs(diff(tlatlim))+1
        latlim=[tlatlim(1)+i-1 min([tlatlim(2),tlatlim(1)+i])];
        Z1t=[];
        if diff(latlim)==0
            continue;
        end
        for j=1:abs(diff(tlonlim))+1
                lonlim=[tlonlim(1)+j-1 min([tlonlim(2),tlonlim(1)+j])];
                if diff(lonlim)==0
                    continue;
                end
                wldwind = wmsfind('nasa.network*elev', 'SearchField', 'serverurl');
                srtmplus = wldwind(demcode);
                samplesPerInterval = dms2degrees([0 0 res]);
                imageFormat = 'image/bil';
                [Zt, R1] = wmsread(srtmplus, 'Latlim', latlim, ...
                'Lonlim', lonlim, 'ImageFormat', imageFormat, ...
                'CellSize', samplesPerInterval);
                if j==1
                    Zt = double(Zt);
                else
                    Zt=double(Zt(:,1:end));
                end
                Z1t=[Z1t Zt];
            
        end
        if i~=1
            Z1t=Z1t(1:end,:);
        end
        Z1=[Z1t;Z1];
            
    end
end

Z1 = double(Z1);
Z1 = flipud(Z1);

end

