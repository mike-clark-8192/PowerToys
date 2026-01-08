// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

namespace FancyZonesEditor.Models
{
    /// <summary>
    /// Represents a keyboard shortcut option for display in dropdowns.
    /// Shows the key value and optionally the name of the layout it's assigned to.
    /// </summary>
    public class KeyDisplayItem
    {
        /// <summary>
        /// Gets or sets the display text shown in the dropdown.
        /// Examples: "None", "1 - TwentyFive", "2"
        /// </summary>
        public string DisplayText { get; set; }

        /// <summary>
        /// Gets or sets the key value used for binding.
        /// Values: "0"-"9" or Properties.Resources.Quick_Key_None
        /// </summary>
        public string KeyValue { get; set; }

        public KeyDisplayItem(string keyValue, string displayText)
        {
            KeyValue = keyValue;
            DisplayText = displayText;
        }
    }
}
