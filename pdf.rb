# encoding: UTF-8
require 'prawn'
require 'prawn/table'
require 'squid'
require './crud'

module PDF
  class File
    attr_reader :filename

    def initialize(filename)
      @filename = filename
    end
    # ширина колонок
    WIDTHS = [200, 200, 120]
    # стили ячеек
    STYLES = {:borders => [:left, :right], :padding => 2}
    # заглавия колонок

    def self.to_pdf(id, date_bid, date_end, client, executor, status, defect, description, count_pavilion,
                    count_maintenances, count_defects, count_pavilion_defects, count_date, count_defects_date)
      @pdf = File.new("./reports/#{Time.now.strftime('Report created: %e\%b\%Y Time: %H:%M.pdf')}")
      Prawn::Document.generate(@pdf.filename) do |pdf|
        # привязываем шрифты
        pdf.font_families.update({'OpenSans' => {
            bold: "#{Prawn::DATADIR}/fonts/OpenSans-Bold.ttf",
            normal: "#{Prawn::DATADIR}/fonts/OpenSans.ttf",
            italic: "#{Prawn::DATADIR}/fonts/OpenSans-Italic.ttf"}})
        pdf.font "OpenSans"
        # дата создания
        pdf.text "Отчет Заявки №#{id}", :size => 15, :style => :bold, :align => :center
        pdf.move_down(18)
        # таблица
        pdf.font "OpenSans", :size => 7
        pdf.table([['Дата подачи', 'Дата завершения', 'Клиент', 'Исполнитель', 'Статус', 'Неисправность'],
                   [date_bid, date_end, client, executor, status, defect]])
        pdf.move_down(20)
        pdf.text "Описание: #{description}"
        pdf.move_down(20)
        pdf.chart({'Остальные случаи' => {"Заявки по данному павильону+\nОстальные заявки" => count_maintenances-count_pavilion,
                                          "Заявки по данному типу неисправности+\nОстальные заявки" => count_maintenances-count_defects,
                                          "Заявки по данному типу неисправности в данном павильоне\n+\nОстальные заявки по данному павильону" => count_pavilion - count_pavilion_defects,
                                          "Заявки по данному типу неисправности\n\nза #{date_bid}\n+\nОстальные заявки за эту дату" => count_date - count_defects_date},
                   'Данный случай' => {"Заявки по данному павильону+\nОстальные заявки" => count_pavilion,
                                       "Заявки по данному типу неисправности+\nОстальные заявки" => count_defects,
                                       "Заявки по данному типу неисправности в данном павильоне\n+\nОстальные заявки по данному павильону" => count_pavilion_defects,
                                       "Заявки по данному типу неисправности\n\nза #{date_bid}\n+\nОстальные заявки за эту дату" => count_defects_date}},
                  {type: :stack, colors: %w(e7a13d bc2d30), labels: [true, true]})
        pdf.move_down(20)
        # добавим время создания внизу страницы
        creation_date = Time.now.strftime("Отчет сгенерирован %e %b %Y в %H:%M")
        pdf.text creation_date, :align => :right, :style => :italic, :size => 9
      end
    end

    def self.get_pdf
      @pdf.filename
    end
  end
end