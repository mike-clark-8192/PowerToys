// Copyright (c) Microsoft Corporation
// The Microsoft Corporation licenses this file to you under the MIT license.
// See the LICENSE file in the project root for more information.

using System;
using System.Globalization;
using System.Windows.Data;
using FancyZonesEditor.Properties;

namespace FancyZonesEditor.Converters
{
    public sealed class QuickKeyToCompactDisplayConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            var key = value as string;
            if (string.IsNullOrEmpty(key) || string.Equals(key, Resources.Quick_Key_None, StringComparison.Ordinal))
            {
                return "—";
            }

            return key;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            return Binding.DoNothing;
        }
    }
}
