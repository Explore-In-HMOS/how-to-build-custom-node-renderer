import { BuilderNode, NodeContent, NodeAdapter, NodeRenderType, typeNode, FrameNode, UIContext } from '@kit.ArkUI';

// data model
class Complication {
  label: string;
  value: string;
  special: ((v: string) => string) | null;

  constructor(
    label: string,
    value: string,
    special: ((v: string) => string) | null = null
  ) {
    this.label = label;
    this.value = value;
    this.special = special;
  }

  specialHandle(value: string): string {
    return this.special === null ? value : this.special(value);
  }
}

// @Builder: how one complication looks
@Builder
function complicationView(c: Complication) {
  Column() {
    Text(c.specialHandle(c.value)).fontSize(18)
    Text(c.label).fontSize(11).fontColor(Color.Gray)
  }
  .justifyContent(FlexAlign.Center)
  .width(60)
  .height(60)
  .borderRadius(14)
  .backgroundColor('#1A1A1A')
  .margin(2)
}

// NodeAdapter: bridges the data source to renderable nodes
class ComplicationAdapter extends NodeAdapter {
  private ui: UIContext;
  private items: Complication[];

  constructor(ui: UIContext, items: Complication[]) {
    super();
    this.ui = ui;
    this.items = items;
    this.totalNodeCount = items.length;
  }

  onCreateChild(index: number): FrameNode {
    const node = new BuilderNode<[Complication]>(this.ui, {
      type: NodeRenderType.RENDER_TYPE_DISPLAY
    });
    node.build(wrapBuilder(complicationView), this.items[index]);
    return node.getFrameNode()!;
  }

  // reposition / resize / swap happen here, only the touched node re-renders
  swap(index: number, item: Complication): void {
    this.items[index] = item;
    this.reloadItem(index, 1);
  }

  addNumberValue(index: number, addNumValue: number): void {
    const current: number = Number(this.items[index].value.replace(/,/g, ''));
    if (!Number.isFinite(current)) {
      return; // not a clean number (e.g. '8,420' or '21°'), skip
    }
    this.items[index].value = `${current + addNumValue}`;
    this.reloadItem(index, 1);
  }
}

@Entry
@Component
struct Index {
  private content: NodeContent = new NodeContent();
  private adapter: ComplicationAdapter | null = null;
  private items: Complication[] = [
    new Complication('STEPS', '8960', (v: string): string => v.replace(/\B(?=(\d{3})+(?!\d))/g, ',')), // 8420 -> 8,420
    new Complication('BPM', '72'), // null, as-is
    new Complication('WEATHER', '21', (v: string): string => `${v}°`)// 21 -> 21°
  ];
  private hrValues: string[] = ['72', '88', '64', '110'];
  private hrIndex: number = 0;
  @State
  private errorMessage: string = '';

  aboutToAppear(): void {
    const context = this.getUIContext();
    // typeNode: a typed FrameNode used as the compositor canvas
    const root: FrameNode = typeNode.createNode(context, 'Row');
    this.adapter = new ComplicationAdapter(context, this.items);
    NodeAdapter.attachNodeAdapter(this.adapter, root);
    try {
      // NodeContent injects the node tree into the declarative UI
      this.content.addFrameNode(root);
    } catch (error) {
      console.error(`Failed to inject the node into UI: ${error}`);
      this.errorMessage = `Couldn't add Node to UI`;
    }
  }

  build() {
    Column() {
      if (this.errorMessage) {
        Text(this.errorMessage)
      } else {
        // node-rendered complications
        ContentSlot(this.content)
        Row() {
          Button('More Steps')
            .fontSize(12)
            .onClick(() => {
              // adding 20 extra steps to the first value, the Steps
              this.adapter?.addNumberValue(0, 20);
            })
          Button('Swap HR')
            .fontSize(12)
            .onClick(() => {
              this.adapter?.swap(1,
                new Complication('BPM', this.hrValues[this.hrIndex = (this.hrIndex + 1) % this.hrValues.length])
              )
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceAround)

      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .justifyContent(FlexAlign.SpaceEvenly)
    .backgroundColor(Color.Black)
  }
}