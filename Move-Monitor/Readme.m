
This Script moniters Mailbox log drive space and mailbox moves and takes required action suspened or resume the move automatically.

Version 1.0 ::: Moniter Log drive space and if it less then 55% suspend moves.
Version 1.5 ::: Target DB Circuler Logging check added, Enable or Disable if required.
Version 2.5 ::: Auto Resume Feature Added for suspened and failed moves as well.
Version 3.0 ::: Twicked the Get DB Size Function so its takes Less CPU overhead, only Queary Log space for DB currently beeing monitored.
Version 3.5 ::: Database Size info added.
Version 4.5 ::: Email Reporting Added for all action.
Version 5.5 ::: Post Move taskes Added, Auto disable circuler logging if log drive free lessthen 90%
Version 6.0 ::: Auto Clean Move Requests, Auto DB Cleanup
Version 6.0 ::: Add throtteling on Mailbox resume action for upto 5 mbx at a time to save the server gets overload
