locals {
  avd_images = {
    // --- EMPFEHLUNG: Windows 11 Multi-Session (aktuellste Version) ---
    "win11-23H2-ms-m365" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "office-365"
      sku       = "win11-23h2-avd-m365" // Multi-session mit vorinstallierten Microsoft 365 Apps
      version   = "latest"
    },
    "win11-23H2-ms" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-11"
      sku       = "win11-23h2-avd" // Multi-session ohne Microsoft 365 Apps
      version   = "latest"
    },

    // --- Windows 10 Multi-Session (bewährt und stabil) ---
    "win10-22H2-ms-m365" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "office-365"
      sku       = "win10-22h2-avd-m365" // Multi-session mit vorinstallierten Microsoft 365 Apps
      version   = "latest"
    },
    "win10-22H2-ms" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-10"
      sku       = "win10-22h2-avd" // Multi-session ohne Microsoft 365 Apps
      version   = "latest"
    },

    // --- Windows Server (falls benötigt) ---
    "win2022-datacenter-g2" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-g2" // Standard Datacenter, Generation 2
      version   = "latest"
    },
    "win2022-datacenter-azure-edition" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition" // Optimiert für Azure, mit Features wie Hotpatching
      version   = "latest"
    },
    "win2019-datacenter-g2" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2019-datacenter-gensecond"
      version   = "latest"
    }
  }
}
