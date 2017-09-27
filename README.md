# ios-sample-GPS
iOS small application to demonstrate the use of location without map and conversion in WGS84 coordinates with [Insiteo SDK](https://github.com/Insiteo/ios-v3)

The application use automaticaly the most suitable map id in accordance with the current location to provide the current coordinates (Latitude - Longitude)

We provide 2 others sample :
- [multi-sites-without-map](https://github.com/Insiteo/ios-sample-GPS/tree/multi-sites-without-map)
- [multi-sites-carto](https://github.com/Insiteo/ios-sample-GPS/tree/multi-sites-carto)

![](https://image.ibb.co/hWVbg5/IMG_0006.png)

## Instalation

You have to set the `ISApiKey` - `ISEServerType` - `ISEServerURL` - `ISSite` values in the Info.plist to use the application with your site.
`ISSite` is your site id.

In the terminal go in the folder that contains the Podfile (usually the same folder that contains the .xcodeproject) and enter `pod install`
