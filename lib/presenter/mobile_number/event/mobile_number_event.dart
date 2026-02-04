import 'package:core/bases/event/base/base_event.dart';
import 'package:country_code_picker/country_code_picker.dart';

class EnableSaveButtonEvent extends BaseEvent {
  final bool isEnabled;

  EnableSaveButtonEvent(this.isEnabled);
}

class CountryCodeChangedEvent extends BaseEvent {
  final CountryCode countryCode;

  CountryCodeChangedEvent(this.countryCode);
}

class SaveMobileNumberEvent extends BaseEvent {
  final String mobileNumber;
  final String countryCode;

  SaveMobileNumberEvent(this.mobileNumber, this.countryCode);
}
