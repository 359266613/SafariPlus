// Copyright (c) 2017-2022 Lars Fröder

// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#import "../SafariPlus.h"
#import "../Defines.h"
#import "../Util.h"
#import "../Enums.h"

%hook NavigationBar

%property (nonatomic,retain) BrowserToolbar *sp_toolbar;

%end

%group iOS12_2to12_4
%hook NavigationBar
- (BrowserToolbar*)toolbarPlacedOnTop
{
	BrowserToolbar* toolbar = %orig;

	self.sp_toolbar = toolbar;

	return toolbar;
}
%end

%end

%group iOS14Up
%hook NavigationBar
- (void)_updateAvailabilityButtonVisibilityForType:(long long)arg1 animated:(BOOL)arg2 showAvailabilityText:(BOOL)arg3 adjustURLLabels:(BOOL)arg4
{
	%orig;
	BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(self.delegate, barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem));
	if(toolbar._reloadItem)
	{
		toolbar._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

%group iOS13_to_13_7
%hook NavigationBar
- (void)_updateAccessoryButtonsVisibility
{
	%orig;
	BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(self.delegate, barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem));
	if(toolbar._reloadItem)
	{
		toolbar._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

%group iOS11_3Up
%hook NavigationBar
- (void)_updateNavigationBarTrailingButtonsVisibility
{
	%orig;
	BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(self.delegate, barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem));
	if(toolbar._reloadItem)
	{
		toolbar._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

%group iOS9Up
%hook NavigationBar
- (void)_updateNavigationBarRightButtonsVisibility
{
	%orig;
	BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(self.delegate, barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem));
	if(toolbar._reloadItem)
	{
		toolbar._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

%group iOS8
%hook NavigationBar
- (void)_updateStopReloadButtonVisibility
{
	%orig;
	BrowserToolbar* toolbar = activeToolbarOrToolbarForBarItemForBrowserController(self.delegate, barButtonItemForSafariPlusOrderItem(BrowserToolbarReloadItem));
	if(toolbar._reloadItem)
	{
		toolbar._reloadItem.enabled = !MSHookIvar<UIButton*>(self, "_reloadButton").hidden;
	}
}
%end

%end

void initNavigationBar()
{
	%init();

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_14_0)
	{
		%init(iOS14Up);
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_13_0)
	{
		%init(iOS13_to_13_7);
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_12_2)
	{
		%init(iOS12_2to12_4);
	}

	if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_3)
	{
		%init(iOS11_3Up);
	}
	else if(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
	{
		%init(iOS9Up);
	}
	else
	{
		%init(iOS8);
	}
}
