package {
// from flex/4.6/frameworks/projects/rpc/src/mx/messaging/config/ServerConfig.as
public class E4X {
	private var xml : XML;
	private var _configFetchedChannels : Object;
	
	/**
	*  @private
	*  This method updates the xml with serverConfig object returned from the
	*  server during initial client connect
	*/
	mx_internal static function updateServerConfigData(serverConfig:ConfigMap, endpoint:String = null):void
	{
		if (serverConfig != null)
		{
			if (endpoint != null)
			{
				// Add the endpoint uri to the list of uris whose configuration
				// has been fetched.
				if (_configFetchedChannels == null)
					_configFetchedChannels = {};

				_configFetchedChannels[endpoint] = true;
			}

			var newServices:XML = <services></services>;
			convertToXML(serverConfig, newServices);

			// Update default-channels of the application.
			xml["default-channels"] = newServices["default-channels"];

			// Update the service destinations.
			for each (var newService:XML in newServices..service)
			{
				var oldServices:XMLList = xml.service.(@id == newService.@id);
				var oldDestinations:XMLList;
				var newDestination:XML;
				// The service already exists, update its destinations.
				if (oldServices.length() != 0)
				{
					var oldService:XML = oldServices[0]; // Service ids are unique.
					for each (newDestination in newService..destination)
					{
						oldDestinations = oldService.destination.(@id == newDestination.@id);
						if (oldDestinations.length() != 0)
							delete oldDestinations[0]; // Destination ids are unique.
						oldService.appendChild(newDestination.copy());
					}
				}
				// The service does not exist which means that this is either a new
				// service with its destinations, or a proxy service (eg. GatewayService)
				// with configuration for existing destinations for other services.
				else
				{
					for each (newDestination in newService..destination)
					{
						oldDestinations = xml..destination.(@id == newDestination.@id);
						if (oldDestinations.length() != 0) // Replace the existing destination.
						{
							oldDestinations[0] = newDestination[0].copy(); // Destination ids are unique.
							delete newService..destination.(@id == newDestination.@id)[0];
						}
					}

					if (newService.children().length() > 0) // Add the new service.
						xml.appendChild(newService);
				}
			}
			// Update the channels
			var newChannels:XMLList = newServices.channels;
			if (newChannels.length() > 0)
			{
				var oldChannels:XML = xml.channels[0];
				if (oldChannels == null || oldChannels.length() == 0)
				{
					xml.appendChild(newChannels);
				}
				// Commenting this section out as there is no real use case
				// for updating channel definitions.
				/*
				else
				{
					for each (var newChannel:XML in newChannels.channel)
					{
						var oldChannel:XMLList = oldChannels.channel.(@id == newChannel.@id);
						if (oldChannel.length() > 0)
						{
							// Assuming only one channel exists with the same id.
							delete oldChannel[0];
						}
						oldChannels.appendChild(newChannel);
					}
				}
				*/
			}
		}
	}
}
}
