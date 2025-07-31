locals {
  avd_images = {
    // --- RECOMMENDATION: Windows 11 Multi-Session (latest version) ---
    "win11-23H2-ms-m365" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "office-365"
      sku       = "win11-23h2-avd-m365" // Multi-session with pre-installed Microsoft 365 Apps
      version   = "latest"
    },
    "win11-23H2-ms" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-11"
      sku       = "win11-23h2-avd" // Multi-session without Microsoft 365 Apps
      version   = "latest"
    },

    // --- Windows 10 Multi-Session (proven and stable) ---
    "win10-22H2-ms-m365" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "office-365"
      sku       = "win10-22h2-avd-m365" // Multi-session with pre-installed Microsoft 365 Apps
      version   = "latest"
    },
    "win10-22H2-ms" = {
      publisher = "MicrosoftWindowsDesktop"
      offer     = "windows-10"
      sku       = "win10-22h2-avd" // Multi-session without Microsoft 365 Apps
      version   = "latest"
    },

    // --- Windows Server (if required) ---
    "win2022-datacenter-g2" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-g2" // Standard Datacenter, Generation 2
      version   = "latest"
    },
    "win2022-datacenter-azure-edition" = {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2022-datacenter-azure-edition" // Optimized for Azure, with features like Hotpatching
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
