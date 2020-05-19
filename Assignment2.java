import java.sql.*;
import java.util.Date;
import java.util.Arrays;
import java.util.List;
import java.lang.Integer;

public class Assignment2 {

   // A connection to the database
   Connection connection;

   // Can use if you wish: seat letters
   List<String> seatLetters = Arrays.asList("A", "B", "C", "D", "E", "F");

   Assignment2() throws SQLException {
      try {
         Class.forName("org.postgresql.Driver");
      } catch (ClassNotFoundException e) {
         e.printStackTrace();
      }
   }

  /**
   * Connects and sets the search path.
   *
   * Establishes a connection to be used for this session, assigning it to
   * the instance variable 'connection'.  In addition, sets the search
   * path to 'air_travel, public'.
   *
   * @param  url       the url for the database
   * @param  username  the username to connect to the database
   * @param  password  the password to connect to the database
   * @return           true if connecting is successful, false otherwise
   */
   public boolean connectDB(String URL, String username, String password) {
      try {
         connection = DriverManager.getConnection(URL, username, password);
         PreparedStatement pStatement = 
           connection.prepareStatement("set search_path to air_travel, public");
         pStatement.executeUpdate();
      } catch (SQLException e) {
         return false;
      }   
      return true;
   }

  /**
   * Closes the database connection.
   *
   * @return true if the closing was successful, false otherwise
   */
   public boolean disconnectDB() {
      if (connection != null){
         try {
            connection.close();
         } catch (SQLException e) {
            return false;
         }
         return true;
      } else {
         return false;
      }
      
   }
   
   /* ======================= Airline-related methods ======================= */

   /**
    * Attempts to book a flight for a passenger in a particular seat class. 
    * Does so by inserting a row into the Booking table.
    *
    * Read handout for information on how seats are booked.
    * Returns false if seat can't be booked, or if passenger or flight cannot be
    * found.
    *
    * 
    * @param  passID     id of the passenger
    * @param  flightID   id of the flight
    * @param  seatClass  the class of the seat (economy, business, or first) 
    * @return            true if the booking was successful, false otherwise. 
    */
   public boolean bookSeat(int passID, int flightID, String seatClass) {
      try {
         String sqlPassenger = 
            "select count(*) as c "+ "from passenger "+ "where id = "+
               Integer.toString(passID);
         String sqlFlight = 
            "select * from flight where id = " + Integer.toString(flightID);
         PreparedStatement prepPassenger = 
            connection.prepareStatement(sqlPassenger);
         ResultSet execPassenger = prepPassenger.executeQuery();
         PreparedStatement prepFlight = connection.prepareStatement(sqlFlight);
         ResultSet execFlight = prepFlight.executeQuery();
         int passCount = 0;
         int flightCount = 0;
         
         while (execPassenger.next()){
            passCount = execPassenger.getInt("c");
         }
         String plane = "";
         while(execFlight.next()){
            flightCount += 1;
            plane = execFlight.getString("plane");
         }
         if ((flightCount == 0)||(passCount == 0)){
            return false;
         }
         int economy_capacity = 0;
         int first_capacity = 0;
         int business_capacity = 0;
         String sqlTextCap = "select * from plane where tail_number = '" + plane
           + "'";
         PreparedStatement prepCap = connection.prepareStatement(sqlTextCap);
         ResultSet execCap = prepCap.executeQuery();
         while(execCap.next()){
            economy_capacity = execCap.getInt("capacity_economy");
            first_capacity = execCap.getInt("capacity_first");
            business_capacity = execCap.getInt("capacity_business");
         }

         if (seatClass.equals("first")) {
            String sqlFirstCount = 
              "select count(*) as passenger_num from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                       " and seat_class = '" + seatClass + "'";
            PreparedStatement prepFirstCount = 
               connection.prepareStatement(sqlFirstCount);
            ResultSet execFirstCount = prepFirstCount.executeQuery();
            int firstCount = 0;
            while(execFirstCount.next()){
               firstCount = execFirstCount.getInt("passenger_num"); 
            }

            if (firstCount >= first_capacity) {
               return false;
            }

            String sqlFirstMax = 
               "select max(row) as max_row from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                     " and seat_class = '" + seatClass + "'";
            PreparedStatement prepFirstMax = 
               connection.prepareStatement(sqlFirstMax);
            ResultSet execFirstMax = prepFirstMax.executeQuery();
            int firstMax = 0;
            while(execFirstMax.next()){
               firstMax = execFirstMax.getInt("max_row");
            }

            String newLetter = getNewLetter(firstCount);
            if(newLetter.equals("A")){
               firstMax += 1;
            }

            String sqlPrice = "select first from price where flight_id = " + 
               Integer.toString(flightID); 
            PreparedStatement prepPrice = connection.prepareStatement(sqlPrice);
            ResultSet execPrice = prepPrice.executeQuery();
            int price = 0;
            while(execPrice.next()){
               price = execPrice.getInt("first"); 
            }

            String sqlId = "select max(id) as max_id from booking"; 
            PreparedStatement prepId = connection.prepareStatement(sqlId);
            ResultSet execId = prepId.executeQuery();
            int new_id = 1;
            while(execId.next()){
               new_id = execId.getInt("max_id") + 1;
            }
            String sqlInsert = "insert into booking "+
                     "values (?,?,?,?,?,seat_class(?),?,?)";
            PreparedStatement prepInsert = 
                           connection.prepareStatement(sqlInsert);
            prepInsert.setInt(1, new_id);
            prepInsert.setInt(2, passID);
            prepInsert.setInt(3, flightID);
            prepInsert.setTimestamp(4, getCurrentTimeStamp());
            prepInsert.setInt(5, price);
            prepInsert.setString(6, seatClass);
            prepInsert.setInt(7, firstMax);
            prepInsert.setString(8, newLetter);
            prepInsert.executeUpdate();
         } else if (seatClass.equals("business")) { 
            String sqlBusinessCount = 
              "select count(*) as passenger_num from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                     " and seat_class = '" + seatClass + "'";
            PreparedStatement prepBusinessCount = 
               connection.prepareStatement(sqlBusinessCount);
            ResultSet execBusinessCount = prepBusinessCount.executeQuery();
            int businessCount = 0;
            while(execBusinessCount.next()){
               businessCount = execBusinessCount.getInt("passenger_num"); 
            }

            if (businessCount >= business_capacity) {
               return false;
            }

            String sqlBusinessMax = 
                  "select max(row) as max_row from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                     " and seat_class = '" + seatClass + "'";
            PreparedStatement prepBusinessMax = 
                     connection.prepareStatement(sqlBusinessMax);
            ResultSet execBusinessMax = prepBusinessMax.executeQuery();
            int businessMax = 0;
            while(execBusinessMax.next()){
               businessMax = execBusinessMax.getInt("max_row");
            }

            // int remainder = (businessCount) % 6;

            // int newRemainder = (remainder + 1) % 6;
            // int newIndex = (newRemainder + 5) % 6;
            // String newLetter = seatLetters.get(newIndex);
            String newLetter = getNewLetter(businessCount);
            if(newLetter.equals("A")){
               businessMax += 1;
            }
            if(businessCount == 0){
               int firstBusinessSeat = (int)Math.ceil((float)first_capacity/6);
               businessMax = firstBusinessSeat + 1;
            }
            
            String sqlPrice = "select business from price where flight_id = " + 
                     Integer.toString(flightID); 
            PreparedStatement prepPrice = connection.prepareStatement(sqlPrice);
            ResultSet execPrice = prepPrice.executeQuery();
            int price = 0;
            while(execPrice.next()){
               price = execPrice.getInt("business"); 
            }

            String sqlId = "select max(id) as max_id from booking"; 
            PreparedStatement prepId = connection.prepareStatement(sqlId);
            ResultSet execId = prepId.executeQuery();
            int new_id = 1;
            while(execId.next()){
               new_id = execId.getInt("max_id") + 1;
            }
  
            String sqlInsert = "insert into booking "+
                     "values (?,?,?,?,?,seat_class(?),?,?)";
            PreparedStatement prepInsert = 
                     connection.prepareStatement(sqlInsert);
            prepInsert.setInt(1, new_id);
            prepInsert.setInt(2, passID);
            prepInsert.setInt(3, flightID);
            prepInsert.setTimestamp(4, getCurrentTimeStamp());
            prepInsert.setInt(5, price);
            prepInsert.setString(6, seatClass);
            prepInsert.setInt(7, businessMax);
            prepInsert.setString(8, newLetter);
            prepInsert.executeUpdate();
         } else {
            String sqlEconomyCount = 
              "select count(*) as passenger_num from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                     " and seat_class = '" + seatClass + "'";
            PreparedStatement prepEconomyCount = 
                              connection.prepareStatement(sqlEconomyCount);
            ResultSet execEconomyCount = prepEconomyCount.executeQuery();
            int economyCount = 0;
            while(execEconomyCount.next()){
               economyCount = execEconomyCount.getInt("passenger_num"); 
            }

            if (economyCount >= economy_capacity + 10) {
               return false;
            }

            String sqlEconomyMax = 
                    "select max(row) as max_row from booking where flight_id = " 
                     + Integer.toString(flightID) + 
                     " and seat_class = '" + seatClass + "'";
            PreparedStatement prepEconomyMax = 
                           connection.prepareStatement(sqlEconomyMax);
            ResultSet execEconomyMax = prepEconomyMax.executeQuery();
            Integer economyMax = 0;
            while(execEconomyMax.next()){
               economyMax = execEconomyMax.getInt("max_row");
            }

            // int remainder = (economyCount) % 6;
            // int newRemainder = (remainder + 1) % 6;
            // int newIndex = (newRemainder + 5) % 6;
            // String newLetter = seatLetters.get(newIndex);
            String newLetter = getNewLetter(economyCount);
            if(newLetter.equals("A")){
               economyMax += 1;
            }
            if(economyCount == 0) {
               int firstEconomySeat = (int)Math.ceil((float)first_capacity/6) + 
                     (int)Math.ceil((float)business_capacity/6);
               economyMax = firstEconomySeat + 1;
            }
            
            if(economyCount >= economy_capacity) {
               economyMax = null;
               newLetter = null;
            }

            String sqlId = "select max(id) as max_id from booking"; 
            PreparedStatement prepId = connection.prepareStatement(sqlId);
            ResultSet execId = prepId.executeQuery();
            int new_id = 1;
            while(execId.next()){
               new_id = execId.getInt("max_id") + 1;
            }

            String sqlPrice = "select economy from price where flight_id = " + 
                     Integer.toString(flightID); 
            PreparedStatement prepPrice = connection.prepareStatement(sqlPrice);
            ResultSet execPrice = prepPrice.executeQuery();
            int price = 0;
            while(execPrice.next()){
               price = execPrice.getInt("economy"); 
            }
 
            String sqlInsert = "insert into booking "+
                     "values (?,?,?,?,?,seat_class(?),?,?)";
            PreparedStatement prepInsert = 
                        connection.prepareStatement(sqlInsert);
            prepInsert.setInt(1, new_id);
            prepInsert.setInt(2, passID);
            prepInsert.setInt(3, flightID);
            prepInsert.setTimestamp(4, getCurrentTimeStamp());
            prepInsert.setInt(5, price);
            prepInsert.setString(6, seatClass);
            if (economyMax != null) {
               prepInsert.setInt(7, economyMax);
               prepInsert.setString(8, newLetter);
            } else {
               prepInsert.setNull(7, Types.NULL);
               prepInsert.setNull(8, Types.NULL);
            }
            prepInsert.executeUpdate();
         }
         return true;
      } catch (SQLException e) {
         return false;
      }
   }

   private String getNewLetter(int count) {
      int remainder = (count) % 6;
      int newRemainder = (remainder + 1) % 6;
      int newIndex = (newRemainder + 5) % 6;
      String newLetter = seatLetters.get(newIndex);
      return newLetter;
   }

   /**
    * Attempts to upgrade overbooked economy passengers to business class
    * or first class (in that order until each seat class is filled).
    * Does so by altering the database records for the bookings such that the
    * seat and seat_class are updated if an upgrade can be processed.
    *
    * Upgrades should happen in order of earliest booking timestamp first.
    *
    * If economy passengers left over without a seat (i.e. more than 10 
    * overbooked passengers or not enough higher class seats), 
    * remove their bookings from the database.
    * 
    * @param  flightID  The flight to upgrade passengers in.
    * @return           the number of passengers upgraded, or -1 if an error 
    * occured.
    */
   public int upgrade(int flightID) {
      try {
         String flight_id = "select id from flight where id = " + 
                  Integer.toString(flightID);
         PreparedStatement execFid = connection.prepareStatement(flight_id);
         ResultSet flight = execFid.executeQuery();
         int flight_no = 0;
         while(flight.next()){
            flight_no = flight.getInt("id");
         }
         if (flight_no == 0){
            return -1;
         }
         String sqlTextflight = 
            "select * from flight where id = " + Integer.toString(flightID);
         PreparedStatement execFlight = 
                     connection.prepareStatement(sqlTextflight);
         ResultSet flightTest = execFlight.executeQuery();
         int flightCount = 0;
        
         String plane = "";
         while(flightTest.next()){
            flightCount = flightCount + 1;
            plane = flightTest.getString("plane");
         }
         
         String sqlTextCap = "select * from plane where tail_number = '" + plane
                + "'";
         PreparedStatement prepCap = connection.prepareStatement(sqlTextCap);
         ResultSet execCap = prepCap.executeQuery();
         int firstCapacity = 0;
         int businessCapacity = 0;
         while(execCap.next()){
            firstCapacity = execCap.getInt("capacity_first");
            businessCapacity = execCap.getInt("capacity_business");
         }
         String sqlSeatOccupied = 
         "select count(*) as count, seat_class  from booking " +
             "where seat_class <> 'economy' and flight_id = " 
         + Integer.toString(flightID) + 
               " group by seat_class order by seat_class";
         PreparedStatement execSeatOccupied = 
                  connection.prepareStatement(sqlSeatOccupied);
         ResultSet seatOccupied = execSeatOccupied.executeQuery();
         int currentBusinessCapacity = 0;
         int currentFirstCapacity = 0;
         while(seatOccupied.next()) {
            if (seatOccupied.getString("seat_class").equals("business")) {
               currentBusinessCapacity = seatOccupied.getInt("count");
            } else {
               currentFirstCapacity = seatOccupied.getInt("count");
            }
         }
         
         int remain_F_Capacity = firstCapacity - currentFirstCapacity;
         int remain_B_Capacity = businessCapacity - currentBusinessCapacity;
         int remainingToUpdate = remain_B_Capacity + remain_F_Capacity;
         if (remainingToUpdate > 10){
            remainingToUpdate = 10;
         }
         int upgradedPassengers = 0; 
         int row_num = 0;
         String seat_letter = " ";
         String s_class = " ";
         String sqlOverbooked = 
            "SELECT * FROM booking WHERE row IS NULL AND " + 
            "letter is NULL and flight_id = " + Integer.toString(flightID) + 
            " ORDER BY datetime";
         PreparedStatement execOverbooked = 
                  connection.prepareStatement(sqlOverbooked);
         ResultSet overBooked = execOverbooked.executeQuery();
         while(upgradedPassengers < remainingToUpdate && overBooked.next()){
            if (remain_B_Capacity > 0) {
               seat_letter = seatLetters.get(currentBusinessCapacity % 6);
               row_num = (int)Math.ceil((float)firstCapacity/6) + 
               (int)(currentBusinessCapacity / 6) + 1; 
               currentBusinessCapacity++;         
               s_class = "business";
               remain_B_Capacity--;
            }
            else{
               seat_letter = seatLetters.get(currentFirstCapacity % 6);
               row_num = (int)(currentFirstCapacity / 6) + 1;
               currentFirstCapacity++;
               s_class = "first";
               remain_F_Capacity--;
            }
            String seatUpgraded = "UPDATE booking SET seat_class = "+
            "seat_class(?), row = " + 
            Integer.toString(row_num) + ", letter = '" + seat_letter  +
             "' WHERE id = " + 
            Integer.toString(overBooked.getInt("id"));
            PreparedStatement execSeatUpgraded = 
            connection.prepareStatement(seatUpgraded);
            execSeatUpgraded.setString(1, s_class);
            execSeatUpgraded.executeUpdate();
            upgradedPassengers++;
         }
         while(overBooked.next()){
            String delEconomy = "DELETE FROM booking WHERE id = " + 
                     Integer.toString(overBooked.getInt("id"));
            PreparedStatement execDelEconomy = 
                     connection.prepareStatement(delEconomy);
            execDelEconomy.executeUpdate();
         }
         return upgradedPassengers;
      } catch (SQLException e) {
         return -1;
      }
   }


   /* ----------------------- Helper functions below  ----------------------- */

    // A helpful function for adding a timestamp to new bookings.
    // Example of setting a timestamp in a PreparedStatement:
    // ps.setTimestamp(1, getCurrentTimeStamp());

    /**
    * Returns a SQL Timestamp object of the current time.
    * 
    * @return           Timestamp of current time.
    */
   private java.sql.Timestamp getCurrentTimeStamp() {
      java.util.Date now = new java.util.Date();
      return new java.sql.Timestamp(now.getTime());
   }

   // Add more helper functions below if desired.


  
  /* ----------------------- Main method below  ------------------------- */

   public static void main(String[] args) {
      // You can put testing code in here. It will not affect our autotester.
      
   }
}
